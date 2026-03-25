import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

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

  async spendOnNewActivity(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (user.totalPoints < 1) {
      throw new BadRequestException('Not enough points');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { totalPoints: { decrement: 1 } },
      }),
      this.prisma.pointTransaction.create({
        data: {
          userId,
          amount: -1,
          transactionType: 'new_activity',
          description: 'Spent point to add new activity',
        },
      }),
    ]);
  }

  async checkCanCreate(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    if (user.totalPoints < 1) {
      throw new BadRequestException('Not enough points');
    }
    return { canCreate: true, remainingPoints: user.totalPoints };
  }
}
