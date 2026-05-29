import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { CreateFriendshipDto } from './dto/create-friendship.dto';
import { UpdateFriendshipDto, FriendshipStatus } from './dto/update-friendship.dto';

@Injectable()
export class FriendshipsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async sendFriendRequest(userId: string, createDto: CreateFriendshipDto) {
    if (userId === createDto.addressee_id) {
      throw new BadRequestException('You cannot send a friend request to yourself');
    }

    const client = this.supabaseService.getAdmin();

    // Check if friendship already exists
    const { data: existing, error: findError } = await client
      .from('friendships')
      .select('id, status')
      .or(
        `and(requester_id.eq.${userId},addressee_id.eq.${createDto.addressee_id}),and(requester_id.eq.${createDto.addressee_id},addressee_id.eq.${userId})`,
      )
      .maybeSingle();

    if (existing) {
      throw new BadRequestException(`Friendship status: ${existing.status}`);
    }

    const { data: friendship, error } = await client
      .from('friendships')
      .insert({
        requester_id: userId,
        addressee_id: createDto.addressee_id,
        status: 'pending',
      })
      .select()
      .single();

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    return friendship;
  }

  async getFriends(userId: string) {
    const client = this.supabaseService.getAdmin();

    const { data, error } = await client
      .from('friendships')
      .select(
        'id, status, created_at, requester:users!requester_id(id, display_name, avatar_url), addressee:users!addressee_id(id, display_name, avatar_url)',
      )
      .or(`requester_id.eq.${userId},addressee_id.eq.${userId}`)
      .eq('status', 'accepted');

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    // Map to a clean list of friends
    return data.map((f) => {
      const friend = f.requester.id === userId ? f.addressee : f.requester;
      return {
        friendshipId: f.id,
        createdAt: f.created_at,
        ...friend,
      };
    });
  }

  async getFriendRequests(userId: string) {
    const client = this.supabaseService.getAdmin();

    const { data, error } = await client
      .from('friendships')
      .select(
        'id, status, created_at, requester:users!requester_id(id, display_name, avatar_url)',
      )
      .eq('addressee_id', userId)
      .eq('status', 'pending');

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    return data;
  }

  async updateFriendship(id: string, userId: string, updateDto: UpdateFriendshipDto) {
    const client = this.supabaseService.getAdmin();

    const { data: friendship, error: findError } = await client
      .from('friendships')
      .select('*')
      .eq('id', id)
      .single();

    if (findError || !friendship) {
      throw new NotFoundException('Friend request not found');
    }

    // Only the addressee can accept or decline
    if (friendship.addressee_id !== userId) {
      throw new ForbiddenException('You cannot update this request');
    }

    const { data: updated, error } = await client
      .from('friendships')
      .update({ status: updateDto.status })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    return updated;
  }

  async removeFriend(id: string, userId: string) {
    const client = this.supabaseService.getAdmin();

    const { data: friendship, error: findError } = await client
      .from('friendships')
      .select('*')
      .eq('id', id)
      .single();

    if (findError || !friendship) {
      throw new NotFoundException('Friendship not found');
    }

    if (friendship.requester_id !== userId && friendship.addressee_id !== userId) {
      throw new ForbiddenException('You are not part of this friendship');
    }

    const { error } = await client.from('friendships').delete().eq('id', id);

    if (error) {
      throw new InternalServerErrorException(error.message);
    }

    return { message: 'Friend removed successfully' };
  }
}
