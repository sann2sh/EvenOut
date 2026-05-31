import { Controller, Get, Param } from '@nestjs/common';
import { BalancesService } from './balances.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('balances')
export class BalancesController {
  constructor(private readonly balancesService: BalancesService) {}

  @Get('groups/:id')
  getGroupBalances(@CurrentUser() user: any, @Param('id') groupId: string) {
    return this.balancesService.getGroupBalances(groupId, user.id);
  }

  @Get('groups/:id/optimized')
  getOptimizedSettlements(@CurrentUser() user: any, @Param('id') groupId: string) {
    return this.balancesService.getOptimizedSettlements(groupId, user.id);
  }

  @Get('me')
  getMyBalances(@CurrentUser() user: any) {
    return this.balancesService.getMyBalances(user.id);
  }
}
