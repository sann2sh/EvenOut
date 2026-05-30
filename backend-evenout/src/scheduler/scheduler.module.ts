import { Module } from '@nestjs/common';
import { SchedulerService } from './scheduler.service';
import { FirebaseModule } from '../firebase/firebase.module';
import { SupabaseModule } from '../common/supabase/supabase.module';

@Module({
  imports: [FirebaseModule, SupabaseModule],
  providers: [SchedulerService],
})
export class SchedulerModule {}
