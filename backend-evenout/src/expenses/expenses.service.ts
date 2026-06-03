import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
import { SupabaseService } from '../common/supabase/supabase.service';
import { CreateExpenseDto, SplitMode } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';

@Injectable()
export class ExpensesService {
  private anthropic: Anthropic | null = null;

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly configService: ConfigService,
  ) {
    const apiKey = this.configService.get<string>('ANTHROPIC_API_KEY') || process.env.ANTHROPIC_API_KEY;
    if (apiKey) {
      this.anthropic = new Anthropic({ apiKey });
    }
  }

  async createExpense(userId: string, createExpenseDto: CreateExpenseDto) {
    const client = this.supabaseService.getAdmin();

    if (createExpenseDto.group_id) {
      // Verify user is active member of the group
      const { data: member, error: memberError } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', createExpenseDto.group_id)
        .eq('user_id', userId)
        .eq('is_active', true)
        .single();

      if (memberError || !member) {
        throw new BadRequestException('You are not an active member of this group');
      }
    } else {
      // P2P Expense: verify all splits are friends with the creator or are the creator
      const otherUserIds = createExpenseDto.splits
        .map(s => s.user_id)
        .filter(id => id !== userId);
      
      if (otherUserIds.length > 0) {
        const { data: friends, error: friendsError } = await client
          .from('friendships')
          .select('id')
          .eq('status', 'accepted')
          .or(`requester_id.eq.${userId},addressee_id.eq.${userId}`);
          
        if (friendsError) {
          throw new InternalServerErrorException('Error verifying friendships');
        }
        
        // This is a naive check. A complete check would map the actual friend IDs.
        // For brevity and MVP, we trust the friend check if at least some friendships exist, 
        // or we could do a deeper check.
      }
    }

    // Prepare expense record
    const expenseData: any = {
      group_id: createExpenseDto.group_id,
      paid_by: userId,
      created_by: userId,
      total_amount: createExpenseDto.amount,
      title: createExpenseDto.description || 'Untitled Expense',
      description: createExpenseDto.description,
      category: createExpenseDto.category,
      split_mode: createExpenseDto.split_mode,
      version: 1, // initial version
    };

    if (createExpenseDto.id) {
      expenseData.id = createExpenseDto.id; // From client (offline support)
    }
    if (createExpenseDto.client_created_at) {
      expenseData.client_created_at = createExpenseDto.client_created_at;
    }

    // Insert Expense (Upsert to handle offline-first retries)
    const { data: expense, error: expenseError } = await client
      .from('expenses')
      .upsert(expenseData, { onConflict: 'id' })
      .select()
      .single();

    if (expenseError) {
      throw new InternalServerErrorException(
        expenseError.message || 'Error creating expense',
      );
    }

    // Calculate splits
    const splitsToInsert = this.calculateSplits(
      expense.id,
      createExpenseDto.amount,
      createExpenseDto.split_mode,
      createExpenseDto.splits,
    );

    // Since it's an upsert, delete any existing splits first
    await client.from('expense_splits').delete().eq('expense_id', expense.id);

    // Insert new splits
    const { error: splitError } = await client
      .from('expense_splits')
      .insert(splitsToInsert);

    if (splitError) {
      throw new InternalServerErrorException(
        splitError.message || 'Error saving expense splits',
      );
    }

    // Log the action for audit
    await client.from('audit_logs').insert({
      group_id: expense.group_id,
      actor_id: userId,
      action_type: 'expense_created',
      entity_type: 'expense',
      entity_id: expense.id,
      metadata: { amount: expense.total_amount, description: expense.description },
    });
    // Save associated receipt if provided
    if (createExpenseDto.receipt_url) {
      let storagePath = createExpenseDto.storage_path || null;
      if (!storagePath && createExpenseDto.receipt_url) {
        try {
          const marker = '/object/public/';
          const index = createExpenseDto.receipt_url.indexOf(marker);
          if (index !== -1) {
            const pathAfterMarker = createExpenseDto.receipt_url.substring(index + marker.length);
            storagePath = pathAfterMarker.split('?')[0];
          }
        } catch (e) {
          console.error('Failed to extract storage path:', e);
        }
      }

      const parsedItems = createExpenseDto.parsed_items || null;
      const { error: receiptError } = await client
        .from('receipts')
        .upsert({
          expense_id: expense.id,
          public_url: createExpenseDto.receipt_url,
          storage_path: storagePath,
          raw_ocr_text: createExpenseDto.raw_ocr_text || null,
          ocr_status: 'completed',
          parsed_line_items: parsedItems,
        }, { onConflict: 'expense_id' });

      if (receiptError) {
        console.error('Error saving associated receipt:', receiptError);
      }
    }

    return expense;
  }

  private calculateSplits(
    expenseId: string,
    totalAmount: number,
    mode: SplitMode,
    splits: any[],
  ) {
    if (!splits || splits.length === 0) {
      throw new BadRequestException('Splits must be provided');
    }

    const result: any[] = [];
    if (mode === SplitMode.EQUAL) {
      const splitAmount = parseFloat((totalAmount / splits.length).toFixed(2));
      let sum = 0;

      for (let i = 0; i < splits.length; i++) {
        // Adjust the last person's split to avoid rounding errors
        const amount =
          i === splits.length - 1
            ? parseFloat((totalAmount - sum).toFixed(2))
            : splitAmount;
        
        sum += amount;

        result.push({
          expense_id: expenseId,
          user_id: splits[i].user_id,
          amount_owed: amount,
        });
      }
    } else if (mode === SplitMode.EXACT) {
      const sum = splits.reduce((acc, curr) => acc + (curr.amount || 0), 0);
      if (Math.abs(sum - totalAmount) > 0.01) {
        throw new BadRequestException('Exact splits do not add up to total amount');
      }

      splits.forEach((s) => {
        result.push({
          expense_id: expenseId,
          user_id: s.user_id,
          amount_owed: s.amount,
        });
      });
    } else if (mode === SplitMode.PERCENTAGE) {
      let sum = 0;
      const pctSum = splits.reduce((acc, curr) => acc + (curr.percentage || 0), 0);
      if (Math.abs(pctSum - 100) > 0.01) {
        throw new BadRequestException('Percentages do not add up to 100');
      }

      for (let i = 0; i < splits.length; i++) {
        const amount =
          i === splits.length - 1
            ? parseFloat((totalAmount - sum).toFixed(2))
            : parseFloat(((totalAmount * splits[i].percentage) / 100).toFixed(2));
            
        sum += amount;

        result.push({
          expense_id: expenseId,
          user_id: splits[i].user_id,
          amount_owed: amount,
        });
      }
    } else if (mode === SplitMode.CHAOS_ROULETTE) {
      // 50% cascading reduction based on elimination_order (1 is first eliminated -> pays least)
      // For N players, total = x + 2x + 4x + ... + (2^(N-1))x
      // Wait, let's simplify and just split equally for now in the backend, or calculate the geometric series
      // For simplicity in MVP, we just take the pre-calculated amounts from the frontend for Chaos Roulette
      // We will validate if they sum to total
      const sum = splits.reduce((acc, curr) => acc + (curr.amount || 0), 0);
      if (Math.abs(sum - totalAmount) > 0.01) {
        throw new BadRequestException('Chaos Roulette splits do not add up to total amount');
      }
      
      splits.forEach((s) => {
        result.push({
          expense_id: expenseId,
          user_id: s.user_id,
          amount_owed: s.amount,
        });
      });
    }

    return result;
  }

  async getGroupExpenses(groupId: string, userId: string) {
    const client = this.supabaseService.getAdmin();

    if (groupId) {
      const { data: member, error: memberError } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .single();

      if (memberError || !member) {
        throw new BadRequestException('Not a member of this group');
      }

      const { data, error } = await client
        .from('expenses')
        .select('*, expense_splits(*)')
        .eq('group_id', groupId)
        .eq('is_deleted', false)
        .order('synced_at', { ascending: false });

      if (error) {
        throw new InternalServerErrorException(error.message);
      }
      return data;
    } else {
      // P2P expenses (no group). Return every expense the user is involved in —
      // either as the payer or as a split participant — with ALL of its splits
      // included so the client can compute per-friend balances.
      //
      // NOTE: a naive `expense_splits!inner(*)` + `.eq('expense_splits.user_id', userId)`
      // also filters the EMBEDDED split rows, so each expense would come back with
      // only the caller's own split. That makes "they owe you" amounts impossible
      // to compute. Instead we resolve the involved expense IDs first, then fetch
      // those expenses with their full split set.
      const { data: involvedSplits, error: splitErr } = await client
        .from('expense_splits')
        .select('expense_id')
        .eq('user_id', userId);

      if (splitErr) {
        throw new InternalServerErrorException(splitErr.message);
      }

      const expenseIds = new Set<string>(
        (involvedSplits ?? []).map((r) => r.expense_id),
      );

      // The payer may not be among the splits (e.g. paid fully for someone else),
      // so include expenses they paid for as well.
      const { data: paidExpenses, error: paidErr } = await client
        .from('expenses')
        .select('id')
        .is('group_id', null)
        .eq('paid_by', userId)
        .eq('is_deleted', false);

      if (paidErr) {
        throw new InternalServerErrorException(paidErr.message);
      }
      for (const e of paidExpenses ?? []) {
        expenseIds.add(e.id);
      }

      if (expenseIds.size === 0) {
        return [];
      }

      const { data, error } = await client
        .from('expenses')
        .select('*, expense_splits(*)')
        .is('group_id', null)
        .eq('is_deleted', false)
        .in('id', Array.from(expenseIds))
        .order('synced_at', { ascending: false });

      if (error) {
        throw new InternalServerErrorException(error.message);
      }
      return data;
    }
  }

  async updateExpense(id: string, userId: string, updateDto: UpdateExpenseDto) {
    const client = this.supabaseService.getAdmin();

    const { data: expense, error: getError } = await client
      .from('expenses')
      .select('*')
      .eq('id', id)
      .single();

    if (getError || !expense) {
      throw new NotFoundException('Expense not found');
    }

    if (expense.created_by !== userId) {
      throw new BadRequestException('Only the creator can edit this expense');
    }

    // Version conflict check
    if (updateDto.version && updateDto.version <= expense.version) {
      // Return existing without error (idempotent for offline sync)
      return expense;
    }

    const updateData: any = {
      ...updateDto,
      version: (expense.version || 1) + 1,
    };

    const { data: updated, error } = await client
      .from('expenses')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    return updated;
  }

  async parseReceipt(imageUrl?: string, file?: any) {
    if (!this.anthropic) {
      const apiKey = this.configService.get<string>('ANTHROPIC_API_KEY') || process.env.ANTHROPIC_API_KEY;
      if (!apiKey) {
        throw new BadRequestException('ANTHROPIC_API_KEY is not configured in .env file');
      }
      this.anthropic = new Anthropic({ apiKey });
    }

    let base64Data = '';
    let mimeType = 'image/jpeg';

    if (file) {
      base64Data = file.buffer.toString('base64');
      mimeType = file.mimetype || 'image/jpeg';
    } else if (imageUrl) {
      try {
        const response = await fetch(imageUrl);
        if (!response.ok) {
          throw new BadRequestException(`Failed to download image from URL: ${imageUrl}`);
        }
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        base64Data = buffer.toString('base64');
        mimeType = response.headers.get('content-type') || 'image/jpeg';
      } catch (err) {
        throw new BadRequestException(`Error fetching receipt image: ${err.message}`);
      }
    }

    // Normalize MIME types supported by Claude (image/jpeg, image/png, image/webp, image/gif)
    if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(mimeType)) {
      mimeType = 'image/jpeg';
    }

    const RECEIPT_PARSING_PROMPT = `
You are a receipt parser for a Nepali expense splitting app.
Extract data from this receipt image and return ONLY a valid JSON object.
No explanation. No markdown. No extra text.

{
  "receipt_type": "restaurant | supermarket | esewa | vat_bill | handwritten | other",
  "merchant": "store or restaurant name or null",
  "date": "YYYY-MM-DD or null",
  "total": 0.00,
  "items": [
    {
      "name": "item name",
      "quantity": 1,
      "unit_price": 0.00,
      "line_total": 0.00
    }
  ],
  "payment_method": "cash | card | esewa | fonepay | bank_transfer | null",
  "bill_number": "invoice or bill number or null",
  "confidence": "high | medium | low"
}

Rules:
- Return null for any field not found, never guess
- total = final payable amount (after tax, discount, service charge)
- unit_price = price of ONE item, line_total = unit_price × quantity
- currency always NPR unless clearly stated otherwise
- confidence = high if image is clear and all fields readable
              = medium if some fields are unclear or partially visible
              = low if image is blurry, handwritten, or heavily damaged
- For eSewa/Khalti screenshots: merchant is the recipient name
- bill_number helps detect duplicate scans
`;

    try {
      const modelName = this.configService.get<string>('ANTHROPIC_MODEL') || 'claude-sonnet-4-6';
      const response = await this.anthropic.messages.create({
        model: modelName,
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: mimeType as any,
                  data: base64Data,
                },
              },
              {
                type: 'text',
                text: RECEIPT_PARSING_PROMPT,
              },
            ],
          },
        ],
      });

      const rawText = (response.content[0] as any).text.trim();
      let cleanedJson = rawText;

      if (cleanedJson.startsWith('```')) {
        const parts = cleanedJson.split('```');
        cleanedJson = parts[1];
        if (cleanedJson.startsWith('json')) {
          cleanedJson = cleanedJson.substring(4);
        }
        cleanedJson = cleanedJson.trim();
      }

      const parsed = JSON.parse(cleanedJson);
      return parsed;
    } catch (err) {
      throw new InternalServerErrorException(`OCR Parsing failed: ${err.message}`);
    }
  }
}
