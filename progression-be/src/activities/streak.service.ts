import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { previousFibonacci } from '../common/utils/fibonacci';
import { daysBetween, getUserToday, getUserYesterday } from '../common/utils/date';

@Injectable()
export class StreakService {
  constructor(private readonly prisma: PrismaService) {}

  async checkAndApplyPenalties(userId: string): Promise<any[]> {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    const timezone = user.timezone ?? 'UTC';
    const today = getUserToday(timezone);
    const yesterday = getUserYesterday(timezone);

    const activities = await this.prisma.activity.findMany({
      where: {
        userId,
        isActive: true,
        isPaused: false,
        currentStreak: { gt: 0 },
      },
    });

    const penalties: any[] = [];

    for (const activity of activities) {
      if (!activity.lastCompletedDate) continue;

      const lastCompleted = new Date(activity.lastCompletedDate);
      lastCompleted.setUTCHours(0, 0, 0, 0);

      // Already completed yesterday or today — no penalty
      if (lastCompleted >= yesterday) continue;

      // Calculate how many days were missed (cascading penalty)
      const missed = daysBetween(lastCompleted, today) - 1;
      if (missed <= 0) continue;

      const oldStreak = activity.currentStreak;
      let newStreak = oldStreak;
      for (let i = 0; i < missed && newStreak > 0; i++) {
        const prev = previousFibonacci(newStreak);
        // Ensure we always decrease by at least 1 to avoid infinite loops
        newStreak = prev < newStreak ? prev : Math.max(0, newStreak - 1);
      }

      const oldTarget = activity.currentTarget;
      // Drop target by one step per day missed, but never below base
      let newTarget = activity.currentTarget;
      for (let i = 0; i < missed; i++) {
        newTarget = Math.max(activity.baseTarget, newTarget - activity.stepSize);
      }

      penalties.push({
        activityId: activity.id,
        activityName: activity.name,
        oldStreak,
        newStreak,
        oldTarget,
        newTarget,
      });
    }

    // Apply all penalties in a single transaction
    if (penalties.length > 0) {
      await this.prisma.$transaction(
        penalties.flatMap((p) => [
          this.prisma.activity.update({
            where: { id: p.activityId },
            data: {
              currentStreak: p.newStreak,
              currentTarget: p.newTarget,
              // Set lastCompletedDate to yesterday to make this idempotent
              lastCompletedDate: yesterday,
            },
          }),
          this.prisma.streakHistory.create({
            data: {
              activityId: p.activityId,
              userId,
              eventType: 'penalty',
              streakValue: p.newStreak,
              targetValue: p.newTarget,
            },
          }),
        ]),
      );
    }

    return penalties;
  }
}
