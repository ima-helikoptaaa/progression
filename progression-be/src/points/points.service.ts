import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { fibonacciAt } from '../common/utils/fibonacci';

@Injectable()
export class PointsService {
  constructor(private readonly prisma: PrismaService) {}

  async getBalance(userId: string) {
    const [user, spentAgg, transactions] = await Promise.all([
      this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
      }),
      this.prisma.pointTransaction.aggregate({
        where: { userId, amount: { lt: 0 } },
        _sum: { amount: true },
      }),
      this.prisma.pointTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 100,
      }),
    ]);

    const spent = Math.abs(spentAgg._sum.amount ?? 0);

    return {
      totalPoints: user.totalPoints,
      lifetimePoints: user.lifetimePoints,
      spentPoints: spent,
      transactions,
    };
  }

  async spendOnUpgrade(userId: string, activityId: string, requestedTarget?: number) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (user.totalPoints < 1) {
      throw new BadRequestException('Not enough points');
    }

    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, isActive: true },
    });
    if (!activity) {
      throw new NotFoundException('Activity not found');
    }

    const oldTarget = activity.currentTarget;
    const newTarget = requestedTarget && requestedTarget > oldTarget
      ? requestedTarget
      : oldTarget + activity.stepSize;

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: 1 } },
      }),
      this.prisma.activity.update({
        where: { id: activityId },
        data: { currentTarget: newTarget },
      }),
      this.prisma.pointTransaction.create({
        data: {
          userId,
          amount: -1,
          transactionType: 'upgrade',
          activityId,
          description: `Upgraded ${activity.name} target: ${oldTarget} -> ${newTarget}`,
        },
      }),
    ]);

    return {
      newTarget,
      remainingPoints: user.totalPoints - 1,
    };
  }

  /**
   * Get the Fibonacci cost for adding the Nth activity (0-indexed existing count).
   * 1st activity = free (0), 2nd = 1, 3rd = 2, 4th = 3, 5th = 5, 6th = 8...
   * This uses fibonacciAt(existingCount) where existingCount is the current number of active activities.
   */
  getActivityCost(existingActiveCount: number): number {
    if (existingActiveCount <= 0) return 0;
    return fibonacciAt(existingActiveCount);
  }

  async spendOnNewActivity(userId: string, existingActiveCount: number) {
    const cost = this.getActivityCost(existingActiveCount);
    if (cost === 0) return;

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (user.totalPoints < cost) {
      throw new BadRequestException(
        `Not enough points. Need ${cost}, have ${user.totalPoints}`,
      );
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: cost } },
      }),
      this.prisma.pointTransaction.create({
        data: {
          userId,
          amount: -cost,
          transactionType: 'new_activity',
          description: `Spent ${cost} point(s) to add activity #${existingActiveCount + 1}`,
        },
      }),
    ]);
  }

  async checkCanCreate(userId: string) {
    const [user, existingCount] = await Promise.all([
      this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      this.prisma.activity.count({ where: { userId, isActive: true } }),
    ]);
    const cost = this.getActivityCost(existingCount);
    if (cost > 0 && user.totalPoints < cost) {
      throw new BadRequestException(
        `Not enough points. Need ${cost}, have ${user.totalPoints}`,
      );
    }
    return { canCreate: true, remainingPoints: user.totalPoints, cost };
  }
}
