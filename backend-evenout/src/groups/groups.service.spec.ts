import { Test, TestingModule } from '@nestjs/testing';
import { GroupsService } from './groups.service';
import { SupabaseService } from '../common/supabase/supabase.service';

describe('GroupsService', () => {
  let service: GroupsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GroupsService,
        {
          provide: SupabaseService,
          useValue: {
            getAdmin: jest.fn(),
            getUserClient: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<GroupsService>(GroupsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
