import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { NudgesService } from './nudges.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SendNudgeDto } from './dto/send-nudge.dto';

@Controller('nudges')
export class NudgesController {
  constructor(private readonly nudgesService: NudgesService) {}

  @Post('send')
  async sendNudge(
    @CurrentUser() user: any,
    @Body() sendNudgeDto: SendNudgeDto,
  ) {
    return this.nudgesService.sendNudge(user.id, sendNudgeDto.debtor_id);
  }
}
