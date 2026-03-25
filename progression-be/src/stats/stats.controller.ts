import { Controller, Get, Param, Query } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { StatsService } from './stats.service';

@Controller('stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('overview')
  async getOverview(@CurrentUser() user: User) {
    return this.statsService.getOverview(user.id);
  }

  @Get('heatmap')
  async getHeatmap(
    @CurrentUser() user: User,
    @Query('days') days?: string,
  ) {
    return this.statsService.getHeatmap(user.id, days ? parseInt(days, 10) : 90);
  }

  @Get('activity/:id/history')
  async getActivityHistory(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Query('days') days?: string,
  ) {
    return this.statsService.getActivityHistory(
      user.id,
      id,
      days ? parseInt(days, 10) : 30,
    );
  }

  @Get('identity/:id')
  async getIdentityStats(
    @CurrentUser() user: User,
    @Param('id') id: string,
  ) {
    return this.statsService.getIdentityStats(user.id, id);
  }
}
