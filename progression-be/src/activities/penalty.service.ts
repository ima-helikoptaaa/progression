import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { previousFibonacci } from '../common/utils/fibonacci';
import {
  daysBetween,
  getUserToday,
  getUserYesterday,
} from '../common/utils/date';

export interface PenaltyResult {
  penalties: PenaltyInfo[];
  incompleteCount: number;
  pointsDeducted: number;
}

export interface PenaltyInfo {
  activityId: string;
  activityName: string;
  oldStreak: number;
  newStreak: number;
  oldTarget: number;
  newTarget: number;
}

@Injectable()
export class PenaltyService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Check and apply penalties for a user.
   * Does NOT mutate lastCompletedDate — uses a separate lastPenaltyDate field
   * to track when the last penalty was applied, so real completion dates
   * are preserved and multi-day gaps are correctly counted.
   */
  async checkAndApplyPenalties(
    prismaClient: PrismaService | any,
    userId: string,
    timezone: string,
  ): Promise<PenaltyResult> {
    const tz = timezone || 'UTC';
    const today = getUserToday(tz);
    const yesterday = getUserYesterday(tz);

    const activities = await prismaClient.activity.findMany({
      where: {
        userId,
        isActive: true,
        isPaused: false,
      },
    });

    const penalties: PenaltyInfo[] = [];
    let incompleteCount = 0;

    for (const activity of activities) {
      const lastCompleted = activity.lastCompletedDate
        ? new Date(activity.lastCompletedDate)
        : null;
      if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);

      // Skip if completed today or yesterday
      if (lastCompleted && lastCompleted.getTime() === today.getTime())
        continue;
      if (lastCompleted && lastCompleted.getTime() === yesterday.getTime())
        continue;

      // Use lastPenaltyDate to determine if we already penalized for this gap
      const lastPenaltyDate = (activity as any).lastPenaltyDate
        ? new Date((activity as any).lastPenaltyDate)
        : null;
      if (lastPenaltyDate) lastPenaltyDate.setUTCHours(0, 0, 0, 0);

      // The "effective" last date is the later of lastCompleted and lastPenaltyDate
      const effectiveLastDate =
        lastPenaltyDate && lastCompleted && lastPenaltyDate > lastCompleted
          ? lastPenaltyDate
          : lastCompleted ?? lastPenaltyDate;

      if (effectiveLastDate) {
        const missed = daysBetween(effectiveLastDate, today) - 1;
        if (missed <= 0) continue;

        incompleteCount++;

        if (activity.currentStreak > 0) {
          const oldStreak = activity.currentStreak;
          let newStreak = oldStreak;
          for (let i = 0; i < missed && newStreak > 0; i++) {
            const prev = previousFibonacci(newStreak);
            newStreak = prev < newStreak ? prev : Math.max(0, newStreak - 1);
          }

          const oldTarget = activity.currentTarget;
          let newTarget = activity.currentTarget;
          for (let i = 0; i < missed; i++) {
            newTarget = Math.max(
              activity.baseTarget,
              newTarget - activity.stepSize,
            );
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
      } else {
        // No completion date and no penalty date — activity never completed
        // Only count as incomplete if the activity was created before yesterday
        const createdAt = new Date(activity.createdAt);
        createdAt.setUTCHours(0, 0, 0, 0);
        if (createdAt < yesterday) {
          incompleteCount++;
        }
      }
    }

    if (penalties.length === 0 && incompleteCount === 0) {
      return { penalties: [], incompleteCount: 0, pointsDeducted: 0 };
    }

    const pointsToDeduct = incompleteCount;

    await prismaClient.$transaction(async (tx: any) => {
      if (pointsToDeduct > 0) {
        await tx.user.update({
          where: { id: userId },
          data: { totalPoints: { decrement: pointsToDeduct } },
        });
        await tx.pointTransaction.create({
          data: {
            userId,
            amount: -pointsToDeduct,
            transactionType: 'daily_penalty',
            description: `Penalty: ${incompleteCount} incomplete activit${incompleteCount === 1 ? 'y' : 'ies'} on ${yesterday.toISOString().split('T')[0]}`,
          },
        });
        await tx.user.updateMany({
          where: { id: userId, totalPoints: { lt: 0 } },
          data: { totalPoints: 0 },
        });
      }

      for (const p of penalties) {
        await tx.activity.update({
          where: { id: p.activityId },
          data: {
            currentStreak: p.newStreak,
            currentTarget: p.newTarget,
            lastPenaltyDate: yesterday,
          },
        });
        await tx.streakHistory.create({
          data: {
            activityId: p.activityId,
            userId,
            eventType: 'penalty',
            streakValue: p.newStreak,
            targetValue: p.newTarget,
          },
        });
      }
    });

    return {
      penalties,
      incompleteCount,
      pointsDeducted: pointsToDeduct,
    };
  }
}
