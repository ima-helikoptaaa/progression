import { Module } from '@nestjs/common';
import { ActivitiesController } from './activities.controller';
import { ActivitiesService } from './activities.service';
import { CompletionService } from './completion.service';
import { StreakService } from './streak.service';
import { PenaltyService } from './penalty.service';
import { PointsModule } from '../points/points.module';

@Module({
  imports: [PointsModule],
  controllers: [ActivitiesController],
  providers: [ActivitiesService, CompletionService, StreakService, PenaltyService],
  exports: [ActivitiesService, StreakService, PenaltyService],
})
export class ActivitiesModule {}
