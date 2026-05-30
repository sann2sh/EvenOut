import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../common/supabase/supabase.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async signUp(signupDto: SignupDto) {
    const client = this.supabaseService.getAdmin();

    const { data, error } = await client.auth.signUp({
      email: signupDto.email,
      password: signupDto.password,
      options: {
        data: {
          display_name: signupDto.display_name,
        },
      },
    });

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      message: 'Signup successful',
      user: data.user,
    };
  }

  async login(loginDto: LoginDto) {
    const client = this.supabaseService.getAdmin();

    const { data, error } = await client.auth.signInWithPassword({
      email: loginDto.email,
      password: loginDto.password,
    });

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      message: 'Login successful',
      access_token: data.session?.access_token,
      refresh_token: data.session?.refresh_token,
      user: data.user,
    };
  }

  async refresh(refreshToken: string) {
    const client = this.supabaseService.getAdmin();
    
    const { data, error } = await client.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      message: 'Token refreshed successfully',
      access_token: data.session?.access_token,
      refresh_token: data.session?.refresh_token,
    };
  }
}
