import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { PenaltyProcessor } from './penalty.processor';
import { PenaltyScheduler } from './penalty.scheduler';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'penalties',
    }),
    ActivitiesModule,
  ],
  providers: [PenaltyProcessor, PenaltyScheduler],
  exports: [BullModule],
})
export class JobsModule {}
