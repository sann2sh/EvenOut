import { Controller, Get, Patch, Body, Param, Query } from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateFcmTokenDto } from './dto/update-fcm-token.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMyProfile(@CurrentUser() user: any) {
    return this.usersService.getProfile(user.id);
  }

  @Patch('me')
  async updateMyProfile(
    @CurrentUser() user: any,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.updateProfile(user.id, updateUserDto);
  }

  @Patch('fcm-token')
  async updateFcmToken(
    @CurrentUser() user: any,
    @Body() updateFcmTokenDto: UpdateFcmTokenDto,
  ) {
    return this.usersService.updateProfile(user.id, updateFcmTokenDto);
  }

  @Get('search')
  async searchUsers(
    @CurrentUser() user: any,
    @Query('query') query: string,
  ) {
    return this.usersService.searchUsers(query, user.id);
  }

  @Get(':id/profile')
  async getUserProfile(@Param('id') id: string) {
    return this.usersService.getProfile(id);
  }
}
