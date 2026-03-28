import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  isFibonacciDay,
  nextFibonacci,
  previousFibonacci,
} from '../common/utils/fibonacci';
import { getUserToday } from '../common/utils/date';

@Injectable()
export class CompletionService {
  constructor(private readonly prisma: PrismaService) {}

  async completeActivity(
    userId: string,
    activityId: string,
    value: number | undefined,
    timezone: string,
    notes?: string,
  ) {
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, isActive: true },
    });
    if (!activity) throw new BadRequestException('Activity not found');
    if (activity.isPaused) throw new BadRequestException('Activity is paused');

    // Default to current target if no value provided
    if (value === undefined) {
      value = activity.currentTarget;
    }

    if (value <= 0) {
      throw new BadRequestException('Value must be greater than 0');
    }

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });

    const today = getUserToday(timezone);

    const lastCompleted = activity.lastCompletedDate
      ? new Date(activity.lastCompletedDate)
      : null;
    if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);

    const completedToday =
      lastCompleted !== null && lastCompleted.getTime() === today.getTime();

    const existingLog = await this.prisma.activityLog.findFirst({
      where: { activityId, completedDate: today },
    });

    if (existingLog) {
      const newAccumulatedValue = existingLog.value + value;

      // Already completed today — overcharge (just accumulate value)
      if (completedToday) {
        const updated = await this.prisma.activityLog.update({
          where: { id: existingLog.id },
          data: { value: { increment: value } },
        });
        return this.buildResponse(activity.currentStreak, false, user.totalPoints, true, updated.value);
      }

      // Partial progress today, check if this pushes past target
      if (newAccumulatedValue >= activity.currentTarget) {
        return this.advanceStreakAndComplete(activity, user, today, existingLog.id, value, newAccumulatedValue, notes);
      }

      // Still partial
      const updated = await this.prisma.activityLog.update({
        where: { id: existingLog.id },
        data: { value: { increment: value } },
      });
      return this.buildResponse(activity.currentStreak, false, user.totalPoints, false, updated.value);
    }

    // No log today — first entry
    if (value >= activity.currentTarget) {
      return this.createLogAndAdvanceStreak(activity, user, today, value, notes);
    }

    // Partial progress — create log, no streak advance
    try {
      await this.prisma.activityLog.create({
        data: {
          activityId,
          userId,
          completedDate: today,
          value,
          targetAtTime: activity.currentTarget,
          streakAtTime: activity.currentStreak,
          earnedPoint: false,
          completionCount: 1,
          notes: notes ?? null,
        },
      });
      return this.buildResponse(activity.currentStreak, false, user.totalPoints, false, value);
    } catch (error: any) {
      if (error?.code === 'P2002') {
        // Race condition — log was created concurrently, add to it
        const concurrentLog = await this.prisma.activityLog.findFirst({
          where: { activityId, completedDate: today },
        });
        if (concurrentLog) {
          const updated = await this.prisma.activityLog.update({
            where: { id: concurrentLog.id },
            data: { value: { increment: value } },
          });
          return this.buildResponse(activity.currentStreak, false, user.totalPoints, false, updated.value);
        }
      }
      throw error;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private buildResponse(
    streak: number,
    earnedPoint: boolean,
    totalPoints: number,
    isOvercharge: boolean,
    valueDoneToday: number,
  ) {
    const nextFib = nextFibonacci(streak);
    const prevFib = previousFibonacci(streak);
    return {
      newStreak: streak,
      earnedPoint,
      isMilestone: earnedPoint,
      nextMilestone: nextFib,
      prevMilestone: prevFib,
      progressToNext: streak > 0 ? (streak - prevFib) / Math.max(1, nextFib - prevFib) : 0,
      totalPoints,
      isOvercharge,
      valueDoneToday,
    };
  }

  private computeNewStreak(activity: any, today: Date): number {
    const yesterday = new Date(today);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);

    const lastCompleted = activity.lastCompletedDate
      ? new Date(activity.lastCompletedDate)
      : null;
    if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);

    if (lastCompleted && lastCompleted.getTime() === yesterday.getTime()) {
      return activity.currentStreak + 1;
    }
    return 1;
  }

  private async runStreakTransaction(
    activity: any,
    user: any,
    today: Date,
    newStreak: number,
    earnedPoint: boolean,
    logAction: (tx: any) => Promise<any>,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const lockedActivity = await tx.activity.update({
        where: { id: activity.id },
        data: {
          currentStreak: newStreak,
          lastCompletedDate: today,
          ...(newStreak > activity.bestStreak ? { bestStreak: newStreak } : {}),
        },
      });

      await logAction(tx);

      await tx.streakHistory.create({
        data: {
          activityId: activity.id,
          userId: user.id,
          eventType: 'advance',
          streakValue: newStreak,
          targetValue: activity.currentTarget,
        },
      });

      let totalPoints = user.totalPoints;
      if (earnedPoint) {
        await tx.user.update({
          where: { id: user.id },
          data: { totalPoints: { increment: 1 }, lifetimePoints: { increment: 1 } },
        });
        await tx.pointTransaction.create({
          data: {
            userId: user.id,
            amount: 1,
            transactionType: 'fibonacci_milestone',
            activityId: activity.id,
            description: `Fibonacci milestone: ${newStreak}-day streak on ${lockedActivity.name}`,
          },
        });
        totalPoints += 1;
      }

      return totalPoints;
    });
  }

  private async createLogAndAdvanceStreak(
    activity: any,
    user: any,
    today: Date,
    value: number,
    notes?: string,
  ) {
    const newStreak = this.computeNewStreak(activity, today);
    const earnedPoint = isFibonacciDay(newStreak);

    try {
      const totalPoints = await this.runStreakTransaction(
        activity, user, today, newStreak, earnedPoint,
        (tx) => tx.activityLog.create({
          data: {
            activityId: activity.id,
            userId: user.id,
            completedDate: today,
            value,
            targetAtTime: activity.currentTarget,
            streakAtTime: newStreak,
            earnedPoint,
            completionCount: 1,
            notes: notes ?? null,
          },
        }),
      );
      return this.buildResponse(newStreak, earnedPoint, totalPoints, false, value);
    } catch (error: any) {
      if (error?.code === 'P2002') {
        // Race: someone else created the log — just accumulate
        const existingLog = await this.prisma.activityLog.findFirst({
          where: { activityId: activity.id, completedDate: today },
        });
        if (existingLog) {
          const updated = await this.prisma.activityLog.update({
            where: { id: existingLog.id },
            data: { value: { increment: value } },
          });
          return this.buildResponse(activity.currentStreak, false, user.totalPoints, false, updated.value);
        }
      }
      throw error;
    }
  }

  private async advanceStreakAndComplete(
    activity: any,
    user: any,
    today: Date,
    existingLogId: string,
    additionalValue: number,
    totalValue: number,
    notes?: string,
  ) {
    const newStreak = this.computeNewStreak(activity, today);
    const earnedPoint = isFibonacciDay(newStreak);

    const totalPoints = await this.runStreakTransaction(
      activity, user, today, newStreak, earnedPoint,
      (tx) => tx.activityLog.update({
        where: { id: existingLogId },
        data: {
          value: { increment: additionalValue },
          streakAtTime: newStreak,
          earnedPoint,
        },
      }),
    );
    return this.buildResponse(newStreak, earnedPoint, totalPoints, false, totalValue);
  }
}
