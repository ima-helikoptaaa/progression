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

  async spendOnUpgrade(
    userId: string,
    activityId: string,
    requestedTarget?: number,
  ) {
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, isActive: true },
    });
    if (!activity) {
      throw new NotFoundException('Activity not found');
    }

    const oldTarget = activity.currentTarget;
    const maxTarget = oldTarget + activity.stepSize * 10;
    const newTarget =
      requestedTarget && requestedTarget > oldTarget
        ? Math.min(requestedTarget, maxTarget)
        : oldTarget + activity.stepSize;

    if (newTarget <= oldTarget) {
      throw new BadRequestException(
        'New target must be greater than current target',
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // Atomic conditional decrement — only succeeds if user has >= 1 point
      const updateResult = await tx.user.updateMany({
        where: { id: userId, totalPoints: { gte: 1 } },
        data: { totalPoints: { decrement: 1 } },
      });

      if (updateResult.count === 0) {
        throw new BadRequestException('Not enough points');
      }

      const updatedUser = await tx.user.findUniqueOrThrow({
        where: { id: userId },
      });

      await tx.activity.update({
        where: { id: activityId },
        data: { currentTarget: newTarget },
      });

      await tx.pointTransaction.create({
        data: {
          userId,
          amount: -1,
          transactionType: 'upgrade',
          activityId,
          description: `Upgraded ${activity.name} target: ${oldTarget} -> ${newTarget}`,
        },
      });

      return updatedUser.totalPoints;
    });

    return {
      newTarget,
      remainingPoints: result,
    };
  }

  getActivityCost(existingActiveCount: number): number {
    if (existingActiveCount <= 0) return 0;
    return fibonacciAt(existingActiveCount);
  }

  async spendOnNewActivity(userId: string, existingActiveCount: number) {
    const cost = this.getActivityCost(existingActiveCount);
    if (cost === 0) return;

    const result = await this.prisma.$transaction(async (tx) => {
      const updateResult = await tx.user.updateMany({
        where: { id: userId, totalPoints: { gte: cost } },
        data: { totalPoints: { decrement: cost } },
      });

      if (updateResult.count === 0) {
        throw new BadRequestException(
          `Not enough points. Need ${cost}, have less than ${cost}`,
        );
      }

      await tx.pointTransaction.create({
        data: {
          userId,
          amount: -cost,
          transactionType: 'new_activity',
          description: `Spent ${cost} point(s) to add activity #${existingActiveCount + 1}`,
        },
      });
    });

    return result;
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
    return {
      canCreate: true,
      remainingPoints: user.totalPoints - cost,
      cost,
    };
  }
}
