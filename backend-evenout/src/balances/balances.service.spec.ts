import { Test, TestingModule } from '@nestjs/testing';
import { BalancesService } from './balances.service';
import { SupabaseService } from '../common/supabase/supabase.service';

describe('BalancesService', () => {
  let service: BalancesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BalancesService,
        {
          provide: SupabaseService,
          useValue: {
            getAdmin: jest.fn(),
            getUserClient: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<BalancesService>(BalancesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
