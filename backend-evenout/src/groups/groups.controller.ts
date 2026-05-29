import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from '@nestjs/common';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { JoinGroupDto } from './dto/join-group.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('groups')
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) {}

  @Post()
  createGroup(@CurrentUser() user: any, @Body() createGroupDto: CreateGroupDto) {
    return this.groupsService.createGroup(user.id, createGroupDto);
  }

  @Get()
  getMyGroups(@CurrentUser() user: any) {
    return this.groupsService.getMyGroups(user.id);
  }

  @Post('join')
  joinGroup(@CurrentUser() user: any, @Body() joinGroupDto: JoinGroupDto) {
    return this.groupsService.joinGroup(user.id, joinGroupDto.invite_code);
  }

  @Get(':id')
  getGroupById(@CurrentUser() user: any, @Param('id') id: string) {
    return this.groupsService.getGroupById(id, user.id);
  }

  @Patch(':id')
  updateGroup(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() updateGroupDto: UpdateGroupDto,
  ) {
    return this.groupsService.updateGroup(id, user.id, updateGroupDto);
  }

  @Delete(':id')
  archiveGroup(@CurrentUser() user: any, @Param('id') id: string) {
    return this.groupsService.updateGroup(id, user.id, { is_archived: true });
  }

  @Get(':id/members')
  getGroupMembers(@CurrentUser() user: any, @Param('id') id: string) {
    return this.groupsService.getGroupMembers(id, user.id);
  }

  @Delete(':id/members/:userId')
  removeMember(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Param('userId') targetUserId: string,
  ) {
    return this.groupsService.removeMember(id, user.id, targetUserId);
  }
}
