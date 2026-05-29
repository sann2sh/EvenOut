import { Test, TestingModule } from '@nestjs/testing';
import { SettlementsService } from './settlements.service';
import { SupabaseService } from '../common/supabase/supabase.service';

describe('SettlementsService', () => {
  let service: SettlementsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SettlementsService,
        {
          provide: SupabaseService,
          useValue: {
            getAdmin: jest.fn(),
            getUserClient: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<SettlementsService>(SettlementsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
