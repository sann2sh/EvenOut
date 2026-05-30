import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export enum SettlementStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  REJECTED = 'rejected',
}

export class CreateSettlementDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @IsUUID()
  group_id?: string;

  @IsUUID()
  payer_id: string;

  @IsUUID()
  payee_id: string;

  @IsNumber()
  @Min(0.01)
  amount: number;



  @IsOptional()
  @IsEnum(SettlementStatus)
  status?: SettlementStatus = SettlementStatus.PENDING;

  @IsOptional()
  @IsString()
  esewa_transaction_id?: string;
}
