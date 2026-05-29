import { IsEnum, IsOptional, IsString, IsNumber } from 'class-validator';
import { SettlementStatus } from './create-settlement.dto';

export class UpdateSettlementDto {
  @IsOptional()
  @IsEnum(SettlementStatus)
  status?: SettlementStatus;

  @IsOptional()
  @IsString()
  esewa_transaction_id?: string;

  @IsOptional()
  @IsNumber()
  version?: number;
}
