import { Test, TestingModule } from '@nestjs/testing';
import { FriendshipsController } from './friendships.controller';
import { FriendshipsService } from './friendships.service';

describe('FriendshipsController', () => {
  let controller: FriendshipsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FriendshipsController],
      providers: [
        {
          provide: FriendshipsService,
          useValue: {
            sendFriendRequest: jest.fn(),
            getFriends: jest.fn(),
            getFriendRequests: jest.fn(),
            updateFriendship: jest.fn(),
            removeFriend: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<FriendshipsController>(FriendshipsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
