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

export class ParsedReceiptItemDto {
  @IsString()
  name: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  unit_price: number;

  @IsOptional()
  @IsNumber()
  line_total?: number;
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

  @IsOptional()
  @IsString()
  receipt_url?: string;

  @IsOptional()
  @IsString()
  storage_path?: string;

  @IsOptional()
  raw_ocr_text?: any;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ParsedReceiptItemDto)
  parsed_items?: ParsedReceiptItemDto[];
}
