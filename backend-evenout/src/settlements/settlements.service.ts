import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { CreateSettlementDto } from './dto/create-settlement.dto';
import { UpdateSettlementDto } from './dto/update-settlement.dto';

@Injectable()
export class SettlementsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createSettlement(userId: string, createDto: CreateSettlementDto) {
    const client = this.supabaseService.getAdmin();

    if (createDto.group_id) {
      // Verify user is active member of the group
      const { data: member, error: memberError } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', createDto.group_id)
        .eq('user_id', userId)
        .eq('is_active', true)
        .single();

      if (memberError || !member) {
        throw new BadRequestException('You are not an active member of this group');
      }
    }

    if (userId !== createDto.payer_id && userId !== createDto.payee_id) {
        throw new BadRequestException('You can only record settlements involving yourself');
    }

    const data: any = {
      ...createDto,
      version: 1,
    };

    const { data: settlement, error } = await client
      .from('settlements')
      .upsert(data, { onConflict: 'id' })
      .select()
      .single();

    if (error) {
      throw new InternalServerErrorException(
        error.message || 'Error creating settlement',
      );
    }

    // Log the action for audit
    await client.from('audit_logs').insert({
      group_id: settlement.group_id,
      actor_id: userId,
      action_type: 'settlement_created',
      entity_type: 'settlement',
      entity_id: settlement.id,
      metadata: { amount: settlement.amount, status: settlement.status },
    });

    return settlement;
  }

  async getGroupSettlements(groupId: string, userId: string) {
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
        .from('settlements')
        .select('*, payer:users!payer_id(id, display_name), payee:users!payee_id(id, display_name)')
        .eq('group_id', groupId)
        .eq('is_deleted', false)
        .order('created_at', { ascending: false });

      if (error) {
        throw new InternalServerErrorException(error.message);
      }
      return data;
    } else {
      // P2P settlements
      const { data, error } = await client
        .from('settlements')
        .select('*, payer:users!payer_id(id, display_name), payee:users!payee_id(id, display_name)')
        .is('group_id', null)
        .or(`payer_id.eq.${userId},payee_id.eq.${userId}`)
        .order('created_at', { ascending: false });

      if (error) {
        throw new InternalServerErrorException(error.message);
      }
      return data;
    }
  }

  async updateSettlement(id: string, userId: string, updateDto: UpdateSettlementDto) {
    const client = this.supabaseService.getAdmin();

    const { data: settlement, error: getError } = await client
      .from('settlements')
      .select('*')
      .eq('id', id)
      .single();

    if (getError || !settlement) {
      throw new NotFoundException('Settlement not found');
    }

    if (userId !== settlement.payer_id && userId !== settlement.payee_id) {
        throw new BadRequestException('You can only edit settlements involving yourself');
    }

    // Version conflict check
    if (updateDto.version && updateDto.version <= settlement.version) {
      return settlement;
    }

    const updateData: any = {
      ...updateDto,
      version: (settlement.version || 1) + 1,
    };

    const { data: updated, error } = await client
      .from('settlements')
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
