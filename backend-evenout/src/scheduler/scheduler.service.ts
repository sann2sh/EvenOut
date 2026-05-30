import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseService } from '../common/supabase/supabase.service';
import { FirebaseService } from '../firebase/firebase.service';

const QUIRKY_CRON_TEMPLATES = [
  "Friendly bot reminder: Your Rs. {amount} debt to {name} has aged beautifully over 3 days. Time to pay up!",
  "A wild debt of Rs. {amount} to {name} is 3 days old! Please feed it some money.",
  "Your debt to {name} (Rs. {amount}) is looking a bit dusty. Settle it now!",
];

@Injectable()
export class SchedulerService {
  private readonly logger = new Logger(SchedulerService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly firebaseService: FirebaseService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_10AM)
  async handleDailyNudges() {
    this.logger.log('Running daily nudge background job...');
    const client = this.supabaseService.getAdmin();

    try {
      // Find expense splits that are unsettled and older than 3 days
      // To prevent sending multiple nudges to the same person, we can aggregate by debtor and creditor
      
      const { data: oldSplits, error } = await client
        .from('expense_splits')
        .select(`
          user_id,
          amount_owed,
          expenses (
            paid_by,
            created_at,
            is_deleted
          )
        `)
        .eq('is_settled', false)
        .lt('created_at', new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString());

      if (error || !oldSplits) {
        this.logger.error('Error fetching old expense splits', error);
        return;
      }

      // Group by debtor -> creditor to calculate total old debt
      // Note: 'expenses' is a nested object returned by Supabase joining
      const debtMap: Record<string, { totalAmount: number, debtorId: string, creditorId: string }> = {};

      for (const split of oldSplits) {
        const expense = Array.isArray(split.expenses) ? split.expenses[0] : split.expenses;
        if (!expense || expense.is_deleted) continue;

        const debtorId = split.user_id;
        const creditorId = expense.paid_by;

        if (debtorId === creditorId) continue;

        const key = `${debtorId}-${creditorId}`;
        if (!debtMap[key]) {
          debtMap[key] = { totalAmount: 0, debtorId, creditorId };
        }
        debtMap[key].totalAmount += parseFloat(split.amount_owed);
      }

      const pairs = Object.values(debtMap);
      if (pairs.length === 0) {
        this.logger.log('No eligible old debts found for nudging.');
        return;
      }

      // Fetch user details for names and FCM tokens
      const userIds = new Set<string>();
      pairs.forEach(p => {
        userIds.add(p.debtorId);
        userIds.add(p.creditorId);
      });

      const { data: users, error: userError } = await client
        .from('users')
        .select('id, display_name, fcm_token')
        .in('id', Array.from(userIds));

      if (userError || !users) {
        this.logger.error('Error fetching users for nudges', userError);
        return;
      }

      const userMap = new Map(users.map(u => [u.id, u]));

      // Send notifications
      for (const pair of pairs) {
        const debtor = userMap.get(pair.debtorId);
        const creditor = userMap.get(pair.creditorId);

        if (!debtor || !debtor.fcm_token || !creditor) continue;

        const template = QUIRKY_CRON_TEMPLATES[Math.floor(Math.random() * QUIRKY_CRON_TEMPLATES.length)];
        const body = template
          .replace('{name}', creditor.display_name || 'your friend')
          .replace('{amount}', pair.totalAmount.toFixed(2));

        try {
          await this.firebaseService.sendPushNotification(
            debtor.fcm_token,
            "⏰ Auto-Nudge Alert!",
            body,
            { type: 'auto_nudge', creditorId: pair.creditorId }
          );
        } catch (pushError) {
          this.logger.error(`Failed to send auto-nudge to ${debtor.id}`, pushError);
        }
      }

      this.logger.log(`Successfully processed ${pairs.length} automated nudges.`);
    } catch (e) {
      this.logger.error('Unexpected error in daily nudges cron', e);
    }
  }
}
