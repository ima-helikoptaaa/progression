import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PenaltyService } from './penalty.service';

@Injectable()
export class StreakService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly penaltyService: PenaltyService,
  ) {}

  async checkAndApplyPenalties(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    const timezone = user.timezone ?? 'UTC';
    const result = await this.penaltyService.checkAndApplyPenalties(
      this.prisma,
      userId,
      timezone,
    );
    return result.penalties;
  }
}
