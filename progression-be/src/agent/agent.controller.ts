import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { Public } from '../common/decorators/public.decorator';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import { ActivitiesService } from '../activities/activities.service';

@Controller('agent')
@Public()
@UseGuards(ApiKeyGuard)
export class AgentController {
  constructor(private readonly activitiesService: ActivitiesService) {}

  @Get('users/:userId/activities')
  async getUserActivities(@Param('userId') userId: string) {
    return this.activitiesService.listActivities(userId);
  }
}
