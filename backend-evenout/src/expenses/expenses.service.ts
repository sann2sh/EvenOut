import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { CreateExpenseDto, SplitMode } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';

@Injectable()
export class ExpensesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createExpense(userId: string, createExpenseDto: CreateExpenseDto) {
    const client = this.supabaseService.getAdmin();

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

    // Prepare expense record
    const expenseData: any = {
      group_id: createExpenseDto.group_id,
      paid_by: userId,
      created_by: userId,
      amount: createExpenseDto.amount,
      currency: createExpenseDto.currency,
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
      metadata: { amount: expense.amount, description: expense.description },
    });

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

    const result = [];
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
      .order('created_at', { ascending: false });

    if (error) {
      throw new InternalServerErrorException(error.message);
    }
    return data;
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
}
