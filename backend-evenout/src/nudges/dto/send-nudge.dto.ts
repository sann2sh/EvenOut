import { IsNotEmpty, IsUUID } from 'class-validator';

export class SendNudgeDto {
  @IsNotEmpty()
  @IsUUID()
  debtor_id: string;
}
