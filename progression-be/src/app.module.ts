import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { BullModule } from '@nestjs/bullmq';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { FirebaseModule } from './firebase/firebase.module';
import { FirebaseAuthGuard } from './common/guards/firebase-auth.guard';
import { SnakeCaseInterceptor } from './common/interceptors/snake-case.interceptor';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ActivitiesModule } from './activities/activities.module';
import { PointsModule } from './points/points.module';
import { StatsModule } from './stats/stats.module';
import { IdentitiesModule } from './identities/identities.module';
import { StacksModule } from './stacks/stacks.module';
import { AgentModule } from './agent/agent.module';
import { JobsModule } from './jobs/jobs.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 60,
      },
    ]),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('REDIS_HOST', 'localhost'),
          port: config.get<number>('REDIS_PORT', 6379),
          ...(config.get<string>('REDIS_PASSWORD')
            ? { password: config.get<string>('REDIS_PASSWORD') }
            : {}),
        },
      }),
      inject: [ConfigService],
    }),
    PrismaModule,
    FirebaseModule,
    AuthModule,
    UsersModule,
    ActivitiesModule,
    PointsModule,
    StatsModule,
    IdentitiesModule,
    StacksModule,
    AgentModule,
    JobsModule,
  ],
  controllers: [AppController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: FirebaseAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: SnakeCaseInterceptor,
    },
  ],
})
export class AppModule {}
