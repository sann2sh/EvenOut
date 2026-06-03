import {
  Injectable,
  InternalServerErrorException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';

export interface UserBalance {
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

  async getUnoptimizedSettlements(groupId: string, userId: string): Promise<OptimizedDebt[]> {
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

    // Aggregate pairwise net balances to avoid A->B and B->A duplicates
    const pairwiseMap = new Map<string, number>();

    for (const row of rawBalances) {
      if (row.user_id === row.counterpart_id) continue;
      
      const amount = parseFloat(row.net_debt);
      // Ensure consistent key ordering so A->B and B->A map to the same key
      const isUserFirst = row.user_id < row.counterpart_id;
      const key = isUserFirst ? `${row.user_id}_${row.counterpart_id}` : `${row.counterpart_id}_${row.user_id}`;
      
      // If user_id is the payer (amount > 0), they owe counterpart_id.
      // If isUserFirst, A owes B. We add amount.
      // If !isUserFirst, B owes A. We subtract amount.
      const currentNet = pairwiseMap.get(key) || 0;
      pairwiseMap.set(key, currentNet + (isUserFirst ? amount : -amount));
    }

    const userIds = new Set<string>();
    for (const key of pairwiseMap.keys()) {
      const [u1, u2] = key.split('_');
      userIds.add(u1);
      userIds.add(u2);
    }

    if (userIds.size === 0) {
      return [];
    }

    const { data: users, error: userError } = await client
      .from('users')
      .select('id, display_name')
      .in('id', Array.from(userIds));

    if (userError) {
      throw new InternalServerErrorException(userError.message);
    }

    const userMap = new Map(users.map((u) => [u.id, u]));
    const unoptimizedSettlements: OptimizedDebt[] = [];

    for (const [key, netAmount] of pairwiseMap.entries()) {
      if (Math.abs(netAmount) < 0.01) continue;

      const [u1, u2] = key.split('_');
      // If netAmount > 0, u1 owes u2.
      // If netAmount < 0, u2 owes u1.
      const payerId = netAmount > 0 ? u1 : u2;
      const payeeId = netAmount > 0 ? u2 : u1;

      unoptimizedSettlements.push({
        payerId,
        payerName: userMap.get(payerId)?.display_name,
        payeeId,
        payeeName: userMap.get(payeeId)?.display_name,
        amount: parseFloat(Math.abs(netAmount).toFixed(2)),
      });
    }

    // Sort by amount descending
    return unoptimizedSettlements.sort((a, b) => b.amount - a.amount);
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

  async getMyBalances(userId: string) {
    const client = this.supabaseService.getAdmin();

    // Fetch from peer_balances view where I am either debtor or creditor
    const { data: rawBalances, error } = await client
      .from('peer_balances')
      .select('*')
      .or(`user_id.eq.${userId},counterpart_id.eq.${userId}`);

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    // Aggregate into a net balance per friend
    const balanceMap = new Map<string, number>();

    for (const row of rawBalances) {
      // Ignore self-debts
      if (row.user_id === row.counterpart_id) continue;

      const amount = parseFloat(row.net_debt);

      // Determine who is the friend
      let friendId: string;
      if (row.user_id === userId) {
        // I am the debtor, I owe the friend `amount`
        friendId = row.counterpart_id;
        balanceMap.set(friendId, (balanceMap.get(friendId) || 0) - amount);
      } else if (row.counterpart_id === userId) {
        // I am the creditor, the friend owes me `amount`
        friendId = row.user_id;
        balanceMap.set(friendId, (balanceMap.get(friendId) || 0) + amount);
      }
    }

    // Get user details to enrich the response
    const friendIds = Array.from(balanceMap.keys());
    let usersMap = new Map<string, any>();

    if (friendIds.length > 0) {
      const { data: users, error: userError } = await client
        .from('users')
        .select('id, display_name, avatar_url')
        .in('id', friendIds);

      if (userError) {
        throw new InternalServerErrorException(userError.message);
      }
      
      usersMap = new Map(users.map((u) => [u.id, u]));
    }

    let totalOwedToMe = 0;
    let totalIOwe = 0;
    const balances: any[] = [];

    for (const [id, balance] of balanceMap.entries()) {
      if (Math.abs(balance) > 0.01) {
        if (balance > 0) {
          totalOwedToMe += balance;
        } else {
          totalIOwe += Math.abs(balance);
        }

        balances.push({
          user_id: id,
          amount: parseFloat(balance.toFixed(2)),
          display_name: usersMap.get(id)?.display_name,
          avatar_url: usersMap.get(id)?.avatar_url,
        });
      }
    }

    return {
      total_owed_to_me: parseFloat(totalOwedToMe.toFixed(2)),
      total_i_owe: parseFloat(totalIOwe.toFixed(2)),
      net_balance: parseFloat((totalOwedToMe - totalIOwe).toFixed(2)),
      balances: balances.sort((a, b) => b.amount - a.amount), // Sort by amount descending
    };
  }
}
