import { IsNotEmpty, IsUUID } from 'class-validator';

export class CreateFriendshipDto {
  @IsNotEmpty()
  @IsUUID()
  addressee_id: string;
}
