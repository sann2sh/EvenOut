import { Injectable, NotFoundException, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateFcmTokenDto } from './dto/update-fcm-token.dto';

@Injectable()
export class UsersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getProfile(userId: string) {
    const client = this.supabaseService.getAdmin();
    const { data, error } = await client
      .from('users')
      .select('id, email, username, phone_number, display_name, avatar_url, split_score, timely_settlements, overdue_days_total, created_at')
      .eq('id', userId)
      .single();

    if (error || !data) {
      if (error?.code === 'PGRST116') {
        throw new NotFoundException('User profile not found');
      }
      throw new InternalServerErrorException(error?.message || 'Error fetching profile');
    }

    return data;
  }

  async updateProfile(userId: string, updateData: UpdateUserDto | UpdateFcmTokenDto) {
    const client = this.supabaseService.getAdmin();
    const { data, error } = await client
      .from('users')
      .update(updateData)
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      // Unique constraint violation on username
      if (error.code === '23505') {
        throw new ConflictException('This username is already taken. Please choose a different one.');
      }
      throw new InternalServerErrorException(error.message || 'Error updating profile');
    }

    return data;
  }

  async searchUsers(query: string, requesterId: string) {
    const client = this.supabaseService.getAdmin();
    const { data, error } = await client
      .from('users')
      .select('id, username, display_name, avatar_url')
      .or(`username.ilike.%${query}%,display_name.ilike.%${query}%`)
      .neq('id', requesterId) // Exclude yourself from results
      .limit(20);

    if (error) {
      throw new InternalServerErrorException(error.message || 'Error searching users');
    }

    return data;
  }
}
