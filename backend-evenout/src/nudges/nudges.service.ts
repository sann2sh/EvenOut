import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { SupabaseService } from '../common/supabase/supabase.service';

const QUIRKY_TEMPLATES = [
  "Did you forget your wallet in 2012? Pay {name} Rs. {amount}!",
  "Your friendship subscription with {name} is past due! Rs. {amount} please.",
  "A wild debt appeared! You owe {name} Rs. {amount}.",
  "Knock knock. Who's there? Your unpaid debt to {name} for Rs. {amount}.",
  "Breaking news: {name} is still waiting for their Rs. {amount}.",
];

@Injectable()
export class NudgesService {
  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly supabaseService: SupabaseService,
  ) {}

  async sendNudge(creditorId: string, debtorId: string) {
    if (creditorId === debtorId) {
      throw new BadRequestException("You cannot nudge yourself.");
    }

    const client = this.supabaseService.getAdmin();

    // Verify debt exists
    const { data: balances, error: balanceError } = await client
      .from('peer_balances')
      .select('net_debt')
      .eq('user_id', debtorId)
      .eq('counterpart_id', creditorId);

    if (balanceError) {
      console.error('Error fetching balances:', balanceError);
      throw new InternalServerErrorException(`Error checking balances: ${balanceError.message}`);
    }

    // Since a pair might be in multiple groups, sum the total debt
    let totalDebt = 0;
    for (const b of balances || []) {
      totalDebt += parseFloat(b.net_debt);
    }

    if (totalDebt <= 0) {
      throw new BadRequestException("This user doesn't owe you any money.");
    }

    // Get creditor name and debtor token
    const { data: users, error: userError } = await client
      .from('users')
      .select('id, display_name, fcm_token')
      .in('id', [creditorId, debtorId]);

    if (userError || !users) {
      throw new InternalServerErrorException("Error fetching user details.");
    }

    const creditor = users.find(u => u.id === creditorId);
    const debtor = users.find(u => u.id === debtorId);

    if (!debtor?.fcm_token) {
      throw new BadRequestException("This user hasn't enabled push notifications.");
    }

    // Select random template
    const template = QUIRKY_TEMPLATES[Math.floor(Math.random() * QUIRKY_TEMPLATES.length)];
    const creditorName = creditor?.display_name || 'your friend';
    const body = template
      .replace('{name}', creditorName)
      .replace('{amount}', totalDebt.toFixed(2));

    // Send push
    await this.firebaseService.sendPushNotification(
      debtor.fcm_token,
      "💸 Friendly Nudge!",
      body,
      { type: 'nudge', creditorId }
    );

    return { success: true, message: "Nudge sent successfully!" };
  }
}
