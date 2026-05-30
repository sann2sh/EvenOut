import { IsNotEmpty, IsString } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsNotEmpty()
  @IsString()
  fcm_token: string;
}
