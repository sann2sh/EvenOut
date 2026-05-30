import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';

@Injectable()
export class GroupsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private generateInviteCode(): string {
    return Math.random().toString(36).substring(2, 10).toUpperCase();
  }

  async createGroup(userId: string, createGroupDto: CreateGroupDto) {
    const client = this.supabaseService.getAdmin();
    const inviteCode = this.generateInviteCode();
    // A deep link format matching the PRD
    const inviteQrUrl = `evenout://join-group?id=${inviteCode}`;

    // 1. Create the group
    const { data: group, error: groupError } = await client
      .from('groups')
      .insert({
        ...createGroupDto,
        created_by: userId,
        invite_code: inviteCode,
        invite_qr_url: inviteQrUrl,
      })
      .select()
      .single();

    if (groupError) {
      throw new InternalServerErrorException(
        groupError.message || 'Error creating group',
      );
    }

    // 2. Add creator as admin
    const { error: memberError } = await client
      .from('group_members')
      .insert({
        group_id: group.id,
        user_id: userId,
        role: 'admin',
      });

    if (memberError) {
      throw new InternalServerErrorException(
        memberError.message || 'Error adding member to group',
      );
    }

    return group;
  }

  async getMyGroups(userId: string) {
    const client = this.supabaseService.getAdmin();
    // Get all groups where user is an active member and group is not archived
    const { data, error } = await client
      .from('group_members')
      .select('groups(*)')
      .eq('user_id', userId)
      .eq('is_active', true)
      .eq('groups.is_archived', false);

    if (error) {
      throw new InternalServerErrorException(
        error.message || 'Error fetching groups',
      );
    }

    // Flatten the result
    return data.map((item) => item.groups).filter((g) => g !== null);
  }

  async getGroupById(groupId: string, userId: string) {
    const client = this.supabaseService.getAdmin();
    // Make sure user is an active member
    const { data: member, error: memberError } = await client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .eq('is_active', true)
      .single();

    if (memberError || !member) {
      throw new ForbiddenException('You are not an active member of this group');
    }

    const { data: group, error: groupError } = await client
      .from('groups')
      .select('*')
      .eq('id', groupId)
      .single();

    if (groupError || !group) {
      throw new NotFoundException('Group not found');
    }

    return group;
  }

  async updateGroup(
    groupId: string,
    userId: string,
    updateGroupDto: UpdateGroupDto,
  ) {
    const client = this.supabaseService.getAdmin();

    // Check if user is admin
    const { data: member, error: memberError } = await client
      .from('group_members')
      .select('role')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .eq('is_active', true)
      .single();

    if (memberError || !member || member.role !== 'admin') {
      throw new ForbiddenException('Only admins can update this group');
    }

    const { data: group, error: groupError } = await client
      .from('groups')
      .update(updateGroupDto)
      .eq('id', groupId)
      .select()
      .single();

    if (groupError) {
      throw new InternalServerErrorException(
        groupError.message || 'Error updating group',
      );
    }

    return group;
  }

  async joinGroup(userId: string, inviteCode: string) {
    const client = this.supabaseService.getAdmin();

    const { data: group, error: groupError } = await client
      .from('groups')
      .select('id')
      .eq('invite_code', inviteCode)
      .eq('is_archived', false)
      .single();

    if (groupError || !group) {
      throw new NotFoundException('Invalid or expired invite code');
    }

    // Check if already a member
    const { data: existingMember } = await client
      .from('group_members')
      .select('id, is_active')
      .eq('group_id', group.id)
      .eq('user_id', userId)
      .maybeSingle();

    if (existingMember) {
      if (existingMember.is_active) {
        return { message: 'Already a member', groupId: group.id };
      } else {
        // Re-activate member
        const { error: updateError } = await client
          .from('group_members')
          .update({ is_active: true, left_at: null })
          .eq('id', existingMember.id);

        if (updateError) {
          throw new InternalServerErrorException('Error re-joining group');
        }
        return { message: 'Successfully rejoined group', groupId: group.id };
      }
    }

    // Insert new member
    const { error: memberError } = await client
      .from('group_members')
      .insert({
        group_id: group.id,
        user_id: userId,
        role: 'member',
      });

    if (memberError) {
      throw new InternalServerErrorException(
        memberError.message || 'Error joining group',
      );
    }

    return { message: 'Successfully joined group', groupId: group.id };
  }

  async getGroupMembers(groupId: string, userId: string) {
    const client = this.supabaseService.getAdmin();

    // Verify requesting user is in the group
    const { data: member, error: memberError } = await client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .eq('is_active', true)
      .single();

    if (memberError || !member) {
      throw new ForbiddenException('You are not a member of this group');
    }

    const { data: members, error } = await client
      .from('group_members')
      .select('role, joined_at, users(id, display_name, avatar_url)')
      .eq('group_id', groupId)
      .eq('is_active', true);

    if (error) {
      throw new InternalServerErrorException(
        error.message || 'Error fetching members',
      );
    }

    return members;
  }

  async removeMember(groupId: string, adminId: string, targetUserId: string) {
    const client = this.supabaseService.getAdmin();

    // If a user is leaving voluntarily, adminId === targetUserId. 
    // If not, verify adminId is actually an admin.
    if (adminId !== targetUserId) {
      const { data: adminMember, error: adminError } = await client
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', adminId)
        .eq('is_active', true)
        .single();

      if (adminError || !adminMember || adminMember.role !== 'admin') {
        throw new ForbiddenException('Only admins can remove other members');
      }
    }

    // Soft delete member
    const { error } = await client
      .from('group_members')
      .update({ is_active: false, left_at: new Date().toISOString() })
      .eq('group_id', groupId)
      .eq('user_id', targetUserId);

    if (error) {
      throw new InternalServerErrorException(
        error.message || 'Error removing member',
      );
    }

    return { message: 'Member removed successfully' };
  }

  async addMember(groupId: string, adderId: string, targetUserId: string) {
    const client = this.supabaseService.getAdmin();

    // 1. Verify the adder is an active member
    const { data: adder, error: adderError } = await client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', adderId)
      .eq('is_active', true)
      .single();

    if (adderError || !adder) {
      throw new ForbiddenException('You must be a member of the group to add someone');
    }

    // 2. Verify adder and target are friends
    const { data: friendship, error: friendError } = await client
      .from('friendships')
      .select('id')
      .eq('status', 'accepted')
      .or(`and(requester_id.eq.${adderId},addressee_id.eq.${targetUserId}),and(requester_id.eq.${targetUserId},addressee_id.eq.${adderId})`)
      .maybeSingle();

    if (friendError || !friendship) {
      throw new ForbiddenException('You can only add people who are your accepted friends');
    }

    // 3. Check if target is already in the group
    const { data: existingMember } = await client
      .from('group_members')
      .select('id, is_active')
      .eq('group_id', groupId)
      .eq('user_id', targetUserId)
      .maybeSingle();

    if (existingMember) {
      if (existingMember.is_active) {
        throw new BadRequestException('User is already a member of this group');
      } else {
        // Re-activate member
        const { error: updateError } = await client
          .from('group_members')
          .update({ is_active: true, left_at: null })
          .eq('id', existingMember.id);

        if (updateError) {
          throw new InternalServerErrorException('Error adding member back to group');
        }
        return { message: 'Member added successfully' };
      }
    }

    // 4. Insert new member
    const { error: insertError } = await client
      .from('group_members')
      .insert({
        group_id: groupId,
        user_id: targetUserId,
        role: 'member',
      });

    if (insertError) {
      throw new InternalServerErrorException(insertError.message || 'Error adding member');
    }

    return { message: 'Member added successfully' };
  }
}
