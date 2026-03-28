import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { previousFibonacci } from '../common/utils/fibonacci';
import { getUserToday, getUserYesterday, daysBetween } from '../common/utils/date';

@Processor('penalties')
export class PenaltyProcessor extends WorkerHost {
  private readonly logger = new Logger(PenaltyProcessor.name);

  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async process(job: Job): Promise<void> {
    this.logger.log(`Running daily penalty check job: ${job.id}`);

    const users = await this.prisma.user.findMany({
      select: { id: true, timezone: true },
    });

    let totalPenalties = 0;
    let totalPointsDeducted = 0;

    for (const user of users) {
      try {
        const result = await this.processUser(user.id, user.timezone);
        totalPenalties += result.penalties;
        totalPointsDeducted += result.pointsDeducted;
      } catch (err) {
        this.logger.error(`Failed to process penalties for user ${user.id}`, err);
      }
    }

    this.logger.log(
      `Penalty job complete: ${users.length} users, ${totalPenalties} penalties, ${totalPointsDeducted} points deducted`,
    );
  }

  private async processUser(
    userId: string,
    timezone: string,
  ): Promise<{ penalties: number; pointsDeducted: number }> {
    const tz = timezone || 'UTC';
    const today = getUserToday(tz);
    const yesterday = getUserYesterday(tz);

    const activities = await this.prisma.activity.findMany({
      where: {
        userId,
        isActive: true,
        isPaused: false,
      },
    });

    const streakPenalties: Array<{
      activityId: string;
      activityName: string;
      newStreak: number;
      newTarget: number;
    }> = [];
    let incompleteCount = 0;

    for (const activity of activities) {
      // Check if activity was completed today or yesterday
      const lastCompleted = activity.lastCompletedDate
        ? new Date(activity.lastCompletedDate)
        : null;
      if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);

      // If completed today, skip
      if (lastCompleted && lastCompleted.getTime() === today.getTime()) continue;

      // If completed yesterday, skip (no penalty yet)
      if (lastCompleted && lastCompleted.getTime() === yesterday.getTime()) continue;

      // Activity was NOT completed yesterday — apply penalty
      incompleteCount++;

      // Only reduce streaks if there's a streak to reduce
      if (activity.currentStreak > 0 && lastCompleted) {
        const missed = daysBetween(lastCompleted, today) - 1;
        if (missed <= 0) continue;

        let newStreak = activity.currentStreak;
        for (let i = 0; i < missed && newStreak > 0; i++) {
          const prev = previousFibonacci(newStreak);
          newStreak = prev < newStreak ? prev : Math.max(0, newStreak - 1);
        }

        let newTarget = activity.currentTarget;
        for (let i = 0; i < missed; i++) {
          newTarget = Math.max(activity.baseTarget, newTarget - activity.stepSize);
        }

        streakPenalties.push({
          activityId: activity.id,
          activityName: activity.name,
          newStreak,
          newTarget,
        });
      }
    }

    if (incompleteCount === 0 && streakPenalties.length === 0) {
      return { penalties: 0, pointsDeducted: 0 };
    }

    // Deduct 1 point per incomplete activity
    const pointsToDeduct = incompleteCount;

    await this.prisma.$transaction([
      // Deduct points (floor at 0)
      ...(pointsToDeduct > 0
        ? [
            this.prisma.user.update({
              where: { id: userId },
              data: {
                totalPoints: {
                  decrement: pointsToDeduct,
                },
              },
            }),
            this.prisma.pointTransaction.create({
              data: {
                userId,
                amount: -pointsToDeduct,
                transactionType: 'daily_penalty',
                description: `Penalty: ${incompleteCount} incomplete activit${incompleteCount === 1 ? 'y' : 'ies'} on ${yesterday.toISOString().split('T')[0]}`,
              },
            }),
          ]
        : []),
      // Apply streak penalties
      ...streakPenalties.flatMap((p) => [
        this.prisma.activity.update({
          where: { id: p.activityId },
          data: {
            currentStreak: p.newStreak,
            currentTarget: p.newTarget,
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
    ]);

    // Ensure points don't go below 0
    await this.prisma.user.updateMany({
      where: { id: userId, totalPoints: { lt: 0 } },
      data: { totalPoints: 0 },
    });

    return { penalties: streakPenalties.length, pointsDeducted: pointsToDeduct };
  }
}
