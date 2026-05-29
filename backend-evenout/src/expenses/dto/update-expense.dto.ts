import { IsBoolean, IsOptional, IsString, IsNumber } from 'class-validator';

export class UpdateExpenseDto {
  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsNumber()
  version?: number; // Client sends expected version to avoid conflicts

  @IsOptional()
  @IsBoolean()
  is_deleted?: boolean;
}
