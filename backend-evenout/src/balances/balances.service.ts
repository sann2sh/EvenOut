import {
  Injectable,
  InternalServerErrorException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';

interface UserBalance {
  userId: string;
  netBalance: number;
  displayName?: string;
  avatarUrl?: string;
}

export interface OptimizedDebt {
  payerId: string;
  payerName?: string;
  payeeId: string;
  payeeName?: string;
  amount: number;
}

@Injectable()
export class BalancesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getGroupBalances(groupId: string, userId: string): Promise<UserBalance[]> {
    const client = this.supabaseService.getAdmin();

    // Verify user is in group
    const { data: member, error: memberError } = await client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .eq('is_active', true)
      .single();

    if (memberError || !member) {
      throw new BadRequestException('You are not an active member of this group');
    }

    // Fetch from peer_balances view
    const { data: rawBalances, error } = await client
      .from('peer_balances')
      .select('*')
      .eq('group_id', groupId);

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    // Aggregate into a net balance per user
    const balanceMap = new Map<string, number>();

    for (const row of rawBalances) {
      const debtorId = row.user_id;
      const creditorId = row.counterpart_id;
      const amount = parseFloat(row.net_debt);

      // debtor owes creditor `amount`.
      // so debtor balance decreases, creditor balance increases.
      balanceMap.set(debtorId, (balanceMap.get(debtorId) || 0) - amount);
      balanceMap.set(creditorId, (balanceMap.get(creditorId) || 0) + amount);
    }

    // Get user details to enrich the response
    const userIds = Array.from(balanceMap.keys());
    if (userIds.length === 0) {
      return [];
    }

    const { data: users, error: userError } = await client
      .from('users')
      .select('id, display_name, avatar_url')
      .in('id', userIds);

    if (userError) {
      throw new InternalServerErrorException(userError.message);
    }

    const userMap = new Map(users.map((u) => [u.id, u]));

    const result: UserBalance[] = [];
    for (const [id, balance] of balanceMap.entries()) {
      // Filter out people with near-zero balances
      if (Math.abs(balance) > 0.01) {
        result.push({
          userId: id,
          netBalance: parseFloat(balance.toFixed(2)),
          displayName: userMap.get(id)?.display_name,
          avatarUrl: userMap.get(id)?.avatar_url,
        });
      }
    }

    return result;
  }

  async getOptimizedSettlements(groupId: string, userId: string): Promise<OptimizedDebt[]> {
    const balances = await this.getGroupBalances(groupId, userId);

    // Greedy simplification algorithm
    const debtors = balances.filter((b) => b.netBalance < -0.01).sort((a, b) => a.netBalance - b.netBalance);
    const creditors = balances.filter((b) => b.netBalance > 0.01).sort((a, b) => b.netBalance - a.netBalance);

    const optimizedSettlements: OptimizedDebt[] = [];

    let i = 0; // Debtors index
    let j = 0; // Creditors index

    while (i < debtors.length && j < creditors.length) {
      const debtor = debtors[i];
      const creditor = creditors[j];

      // The amount to settle is the minimum of what the debtor owes and what the creditor is owed
      const amountToSettle = Math.min(Math.abs(debtor.netBalance), creditor.netBalance);

      if (amountToSettle > 0.01) {
        optimizedSettlements.push({
          payerId: debtor.userId,
          payerName: debtor.displayName,
          payeeId: creditor.userId,
          payeeName: creditor.displayName,
          amount: parseFloat(amountToSettle.toFixed(2)),
        });
      }

      // Adjust balances
      debtor.netBalance += amountToSettle;
      creditor.netBalance -= amountToSettle;

      // Move to the next person if their balance is cleared
      if (Math.abs(debtor.netBalance) < 0.01) i++;
      if (creditor.netBalance < 0.01) j++;
    }

    return optimizedSettlements;
  }
}
