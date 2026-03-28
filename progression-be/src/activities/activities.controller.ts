import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { ActivitiesService } from './activities.service';
import { CompletionService } from './completion.service';
import { StreakService } from './streak.service';
import { PointsService } from '../points/points.service';

const COLOR_HEX_REGEX = /^#[0-9A-Fa-f]{6}$/;

@Controller('activities')
export class ActivitiesController {
  constructor(
    private readonly activitiesService: ActivitiesService,
    private readonly completionService: CompletionService,
    private readonly streakService: StreakService,
    private readonly pointsService: PointsService,
  ) {}

  @Get()
  async listActivities(@CurrentUser() user: User) {
    return this.activitiesService.listActivities(user.id, user.timezone);
  }

  @Get('penalties')
  async checkPenalties(@CurrentUser() user: User) {
    const penalties = await this.streakService.checkAndApplyPenalties(user.id);
    return { penalties, totalPoints: user.totalPoints };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createActivity(
    @CurrentUser() user: User,
    @Body()
    body: {
      name: string;
      emoji?: string;
      unit?: string;
      base_target?: number;
      current_target?: number;
      step_size?: number;
      color_hex?: string;
      sort_order?: number;
      identity_id?: string;
      cue_time?: string;
      cue_location?: string;
      tracking_mode?: string;
    },
  ) {
    // Input validation
    if (!body.name || body.name.trim().length === 0) {
      throw new BadRequestException('Activity name is required');
    }
    if (body.name.trim().length > 50) {
      throw new BadRequestException(
        'Activity name must be 50 characters or less',
      );
    }
    if (body.base_target !== undefined && body.base_target <= 0) {
      throw new BadRequestException('Base target must be greater than 0');
    }
    if (body.step_size !== undefined && body.step_size <= 0) {
      throw new BadRequestException('Step size must be greater than 0');
    }
    if (
      body.color_hex !== undefined &&
      !COLOR_HEX_REGEX.test(body.color_hex)
    ) {
      throw new BadRequestException(
        'Color must be a valid hex code (e.g., #6C5CE7)',
      );
    }

    const existingCount = await this.activitiesService.countActiveActivities(
      user.id,
    );
    // Fibonacci cascading cost: 1st free, 2nd=1pt, 3rd=2pt, 4th=3pt, 5th=5pt...
    await this.pointsService.spendOnNewActivity(user.id, existingCount);

    return this.activitiesService.createActivity(user.id, {
      name: body.name.trim(),
      emoji: body.emoji,
      unit: body.unit,
      baseTarget: body.base_target,
      currentTarget: body.current_target,
      stepSize: body.step_size,
      colorHex: body.color_hex,
      sortOrder: body.sort_order,
      identityId: body.identity_id,
      cueTime: body.cue_time,
      cueLocation: body.cue_location,
      trackingMode: body.tracking_mode,
    });
  }

  @Put(':id')
  async updateActivity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      emoji?: string;
      color_hex?: string;
      sort_order?: number;
      unit?: string;
      identity_id?: string;
      stack_id?: string;
      stack_order?: number;
      cue_time?: string;
      cue_location?: string;
      tracking_mode?: string;
    },
  ) {
    if (body.name !== undefined && body.name.trim().length === 0) {
      throw new BadRequestException('Activity name cannot be empty');
    }
    if (body.name !== undefined && body.name.trim().length > 50) {
      throw new BadRequestException(
        'Activity name must be 50 characters or less',
      );
    }
    if (
      body.color_hex !== undefined &&
      !COLOR_HEX_REGEX.test(body.color_hex)
    ) {
      throw new BadRequestException(
        'Color must be a valid hex code (e.g., #6C5CE7)',
      );
    }

    return this.activitiesService.updateActivity(user.id, id, {
      name: body.name?.trim(),
      emoji: body.emoji,
      colorHex: body.color_hex,
      sortOrder: body.sort_order,
      unit: body.unit,
      identityId: body.identity_id,
      stackId: body.stack_id,
      stackOrder: body.stack_order,
      cueTime: body.cue_time,
      cueLocation: body.cue_location,
      trackingMode: body.tracking_mode,
    }, user.timezone);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteActivity(@CurrentUser() user: User, @Param('id') id: string) {
    await this.activitiesService.deleteActivity(user.id, id);
  }

  @Post(':id/complete')
  async completeActivity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { value?: number; notes?: string },
  ) {
    return this.completionService.completeActivity(
      user.id,
      id,
      body.value ?? undefined,
      user.timezone,
      body.notes,
    );
  }

  @Post(':id/pause')
  async togglePause(@CurrentUser() user: User, @Param('id') id: string) {
    return this.activitiesService.togglePause(user.id, id);
  }
}
