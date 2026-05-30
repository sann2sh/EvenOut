import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { FriendshipsService } from './friendships.service';
import { CreateFriendshipDto } from './dto/create-friendship.dto';
import { UpdateFriendshipDto } from './dto/update-friendship.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('friendships')
export class FriendshipsController {
  constructor(private readonly friendshipsService: FriendshipsService) {}

  @Post('requests')
  sendFriendRequest(@CurrentUser() user: any, @Body() createDto: CreateFriendshipDto) {
    return this.friendshipsService.sendFriendRequest(user.id, createDto);
  }

  @Get()
  getFriends(@CurrentUser() user: any) {
    return this.friendshipsService.getFriends(user.id);
  }

  @Get('requests')
  getFriendRequests(@CurrentUser() user: any) {
    return this.friendshipsService.getFriendRequests(user.id);
  }

  @Get('requests/sent')
  getSentFriendRequests(@CurrentUser() user: any) {
    return this.friendshipsService.getSentFriendRequests(user.id);
  }

  @Patch('requests/:id')
  updateFriendship(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() updateDto: UpdateFriendshipDto,
  ) {
    return this.friendshipsService.updateFriendship(id, user.id, updateDto);
  }

  @Delete(':id')
  removeFriend(@CurrentUser() user: any, @Param('id') id: string) {
    return this.friendshipsService.removeFriend(id, user.id);
  }
}
