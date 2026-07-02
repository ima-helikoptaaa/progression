import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { StatsService } from './stats.service';

function parseDays(
  value: string | undefined,
  defaultDays: number,
  max: number,
): number {
  if (!value) return defaultDays;
  const days = parseInt(value, 10);
  if (isNaN(days) || days < 1 || days > max) {
    throw new BadRequestException(`days must be between 1 and ${max}`);
  }
  return days;
}

@Controller('stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('overview')
  async getOverview(@CurrentUser() user: User) {
    return this.statsService.getOverview(user.id, user.timezone);
  }

  @Get('heatmap')
  async getHeatmap(@CurrentUser() user: User, @Query('days') days?: string) {
    return this.statsService.getHeatmap(
      user.id,
      parseDays(days, 90, 365),
      user.timezone,
    );
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
      parseDays(days, 30, 365),
      user.timezone,
    );
  }

  @Get('identity/:id')
  async getIdentityStats(@CurrentUser() user: User, @Param('id') id: string) {
    return this.statsService.getIdentityStats(user.id, id, user.timezone);
  }
}
