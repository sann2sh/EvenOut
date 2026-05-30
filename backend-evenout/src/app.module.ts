import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SupabaseModule } from './common/supabase/supabase.module';
import { UsersModule } from './users/users.module';
import { SupabaseAuthGuard } from './common/guards/supabase-auth.guard';
import { GroupsModule } from './groups/groups.module';
import { ExpensesModule } from './expenses/expenses.module';
import { SettlementsModule } from './settlements/settlements.module';
import { BalancesModule } from './balances/balances.module';
import { FriendshipsModule } from './friendships/friendships.module';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [
    // Load .env globally
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Global Supabase client
    SupabaseModule,

    UsersModule,

    GroupsModule,

    ExpensesModule,

    SettlementsModule,

    BalancesModule,

    FriendshipsModule,

    AuthModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: SupabaseAuthGuard,
    },
  ],
})
export class AppModule {}
