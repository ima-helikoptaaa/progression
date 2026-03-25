import { Module } from '@nestjs/common';
import { AgentController } from './agent.controller';
import { ActivitiesModule } from '../activities/activities.module';

@Module({
  imports: [ActivitiesModule],
  controllers: [AgentController],
})
export class AgentModule {}
