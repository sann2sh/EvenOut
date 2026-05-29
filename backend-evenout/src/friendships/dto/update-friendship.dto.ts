import { IsEnum, IsNotEmpty } from 'class-validator';

export enum FriendshipStatus {
  ACCEPTED = 'accepted',
  DECLINED = 'declined',
  BLOCKED = 'blocked',
}

export class UpdateFriendshipDto {
  @IsNotEmpty()
  @IsEnum(FriendshipStatus)
  status: FriendshipStatus;
}
