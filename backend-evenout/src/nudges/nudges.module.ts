import { Module } from '@nestjs/common';
import { NudgesController } from './nudges.controller';
import { NudgesService } from './nudges.service';
import { FirebaseModule } from '../firebase/firebase.module';
import { SupabaseModule } from '../common/supabase/supabase.module';

@Module({
  imports: [FirebaseModule, SupabaseModule],
  controllers: [NudgesController],
  providers: [NudgesService],
})
export class NudgesModule {}
