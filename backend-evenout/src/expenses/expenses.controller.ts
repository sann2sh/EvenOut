import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  Query,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ExpensesService } from './expenses.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('expenses')
export class ExpensesController {
  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  createExpense(
    @CurrentUser() user: any,
    @Body() createExpenseDto: CreateExpenseDto,
  ) {
    return this.expensesService.createExpense(user.id, createExpenseDto);
  }

  @Get()
  getGroupExpenses(@CurrentUser() user: any, @Query('groupId') groupId: string) {
    return this.expensesService.getGroupExpenses(groupId, user.id);
  }

  @Patch(':id')
  updateExpense(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() updateExpenseDto: UpdateExpenseDto,
  ) {
    return this.expensesService.updateExpense(id, user.id, updateExpenseDto);
  }

  @Post('parse-receipt')
  @UseInterceptors(FileInterceptor('file'))
  async parseReceipt(
    @CurrentUser() user: any,
    @Body('imageUrl') imageUrl?: string,
    @UploadedFile() file?: any,
  ) {
    if (!imageUrl && !file) {
      throw new BadRequestException('Either imageUrl or file must be provided');
    }
    return this.expensesService.parseReceipt(imageUrl, file);
  }
}
