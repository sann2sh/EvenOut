import { Controller, Post, Body, Get, Param, Patch, Query } from '@nestjs/common';
import { SettlementsService } from './settlements.service';
import { CreateSettlementDto } from './dto/create-settlement.dto';
import { UpdateSettlementDto } from './dto/update-settlement.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('settlements')
export class SettlementsController {
  constructor(private readonly settlementsService: SettlementsService) {}

  @Post()
  createSettlement(
    @CurrentUser() user: any,
    @Body() createDto: CreateSettlementDto,
  ) {
    return this.settlementsService.createSettlement(user.id, createDto);
  }

  @Get()
  getGroupSettlements(@CurrentUser() user: any, @Query('groupId') groupId: string) {
    return this.settlementsService.getGroupSettlements(groupId, user.id);
  }

  @Patch(':id')
  updateSettlement(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() updateDto: UpdateSettlementDto,
  ) {
    return this.settlementsService.updateSettlement(id, user.id, updateDto);
  }
}
