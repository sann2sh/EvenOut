import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  IsDateString,
  ValidateNested,
  IsArray,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum SplitMode {
  EQUAL = 'equal',
  EXACT = 'exact',
  PERCENTAGE = 'percentage',
  CHAOS_ROULETTE = 'chaos_roulette',
}

export class ExpenseSplitDto {
  @IsUUID()
  user_id: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  amount?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  percentage?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  elimination_order?: number; // Used for chaos roulette
}

export class CreateExpenseDto {
  @IsOptional()
  @IsUUID()
  id?: string; // Client can provide this for offline-first support

  @IsOptional()
  @IsUUID()
  group_id?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;



  @IsString()
  description: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsEnum(SplitMode)
  split_mode: SplitMode;

  @IsOptional()
  @IsDateString()
  client_created_at?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ExpenseSplitDto)
  splits: ExpenseSplitDto[];
}
