import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { PointsService } from './points.service';

@Controller('points')
export class PointsController {
  constructor(private readonly pointsService: PointsService) {}

  @Get()
  async getPoints(@CurrentUser() user: User) {
    return this.pointsService.getBalance(user.id);
  }

  @Post('spend')
  async spendPoints(
    @CurrentUser() user: User,
    @Body() body: { action: string; activity_id?: string; new_target?: number },
  ) {
    if (body.action === 'upgrade') {
      if (!body.activity_id) {
        throw new BadRequestException('activity_id required for upgrade');
      }
      return this.pointsService.spendOnUpgrade(user.id, body.activity_id, body.new_target);
    } else if (body.action === 'new_activity') {
      return this.pointsService.checkCanCreate(user.id);
    }
    throw new BadRequestException('Invalid action');
  }
}
