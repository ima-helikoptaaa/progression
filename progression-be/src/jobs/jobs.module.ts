import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { PenaltyProcessor } from './penalty.processor';
import { PenaltyScheduler } from './penalty.scheduler';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'penalties',
    }),
  ],
  providers: [PenaltyProcessor, PenaltyScheduler],
  exports: [BullModule],
})
export class JobsModule {}
