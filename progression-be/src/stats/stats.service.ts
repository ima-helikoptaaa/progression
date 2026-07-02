import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { getUserToday } from '../common/utils/date';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(userId: string, timezone = 'UTC') {
    const [totalCompletions, bestStreakResult, activeActivities, user] =
      await Promise.all([
        this.prisma.activityLog.count({ where: { userId } }),
        this.prisma.activity.aggregate({
          where: { userId, isActive: true },
          _max: { bestStreak: true },
        }),
        this.prisma.activity.count({ where: { userId, isActive: true } }),
        this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      ]);

    const today = getUserToday(timezone);
    const dayOfWeek = today.getUTCDay();
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const weekStart = new Date(today);
    weekStart.setUTCDate(today.getUTCDate() - mondayOffset);

    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setUTCDate(prevWeekStart.getUTCDate() - 7);

    const [currentWeek, previousWeek] = await Promise.all([
      this.prisma.activityLog.count({
        where: { userId, completedDate: { gte: weekStart } },
      }),
      this.prisma.activityLog.count({
        where: {
          userId,
          completedDate: { gte: prevWeekStart, lt: weekStart },
        },
      }),
    ]);

    return {
      totalCompletions,
      bestStreak: bestStreakResult._max.bestStreak ?? 0,
      totalPointsEarned: user.lifetimePoints,
      activeActivities,
      currentWeekCompletions: currentWeek,
      previousWeekCompletions: previousWeek,
    };
  }

  async getHeatmap(userId: string, days: number = 90, timezone = 'UTC') {
    const today = getUserToday(timezone);
    const startDate = new Date(today);
    startDate.setUTCDate(startDate.getUTCDate() - (days - 1));

    const totalActivities = await this.prisma.activity.count({
      where: { userId, isActive: true, isPaused: false },
    });
    const denominator = Math.max(totalActivities, 1);

    const logs = await this.prisma.activityLog.groupBy({
      by: ['completedDate'],
      where: { userId, completedDate: { gte: startDate, lte: today } },
      _count: { id: true },
      _sum: { completionCount: true },
    });

    // Build a dense map of all days
    const logMap = new Map<string, { count: number; totalCompletions: number }>();
    for (const row of logs) {
      const dateKey = row.completedDate.toISOString().split('T')[0];
      const count = row._count.id;
      const totalCompletions = row._sum.completionCount ?? count;
      logMap.set(dateKey, { count, totalCompletions });
    }

    // Generate dense array covering every day in the range
    const entries: Array<{
      date: Date;
      count: number;
      ratio: number;
      totalCompletions: number;
      intensity: number;
    }> = [];

    const cursor = new Date(startDate);
    while (cursor <= today) {
      const dateKey = cursor.toISOString().split('T')[0];
      const log = logMap.get(dateKey);
      const count = log?.count ?? 0;
      const totalCompletions = log?.totalCompletions ?? 0;
      const baseRatio = Math.min(1.0, count / denominator);
      const overchargeBoost = Math.min(
        1.0,
        totalCompletions / Math.max(1, denominator * 2),
      );
      const intensity =
        count > 0
          ? Math.min(1.0, baseRatio * 0.7 + overchargeBoost * 0.3)
          : 0;

      entries.push({
        date: new Date(cursor),
        count,
        ratio: baseRatio,
        totalCompletions,
        intensity,
      });

      cursor.setUTCDate(cursor.getUTCDate() + 1);
    }

    // Return the starting weekday (0=Sunday) so the frontend can align the grid
    const startWeekday = startDate.getUTCDay();

    return { entries, totalActivities: denominator, startWeekday };
  }

  async getActivityHistory(
    userId: string,
    activityId: string,
    days: number = 30,
    timezone = 'UTC',
  ) {
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId },
    });
    if (!activity) throw new NotFoundException('Activity not found');

    const today = getUserToday(timezone);
    const startDate = new Date(today);
    startDate.setUTCDate(startDate.getUTCDate() - days);

    const logs = await this.prisma.activityLog.findMany({
      where: { activityId, completedDate: { gte: startDate } },
      orderBy: { completedDate: 'asc' },
    });

    const entries = logs.map((log) => ({
      date: log.completedDate,
      value: log.value,
      target: log.targetAtTime,
      streak: log.streakAtTime,
      earnedPoint: log.earnedPoint,
    }));

    return {
      activityId: activity.id,
      activityName: activity.name,
      entries,
    };
  }

  async getIdentityStats(userId: string, identityId: string, timezone = 'UTC') {
    const activities = await this.prisma.activity.findMany({
      where: { userId, identityId, isActive: true },
    });

    if (activities.length === 0) {
      return {
        identityId,
        totalActivities: 0,
        totalCompletions: 0,
        bestStreak: 0,
        weeklyCompletionRate: 0.0,
        activityStats: [],
      };
    }

    const activityIds = activities.map((a) => a.id);

    const totalCompletions = await this.prisma.activityLog.count({
      where: { activityId: { in: activityIds } },
    });

    const bestStreak = Math.max(...activities.map((a) => a.bestStreak), 0);

    const today = getUserToday(timezone);
    const dayOfWeek = today.getUTCDay();
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const weekStart = new Date(today);
    weekStart.setUTCDate(today.getUTCDate() - mondayOffset);

    const weekCompletions = await this.prisma.activityLog.count({
      where: {
        activityId: { in: activityIds },
        completedDate: { gte: weekStart },
      },
    });

    const daysElapsed =
      Math.floor(
        (today.getTime() - weekStart.getTime()) / (1000 * 60 * 60 * 24),
      ) + 1;
    const weeklyRate = Math.min(
      1.0,
      weekCompletions / Math.max(1, activities.length * daysElapsed),
    );

    const activityStats = activities.map((a) => {
      const lastCompleted = a.lastCompletedDate
        ? new Date(a.lastCompletedDate)
        : null;
      if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);
      const completedToday =
        lastCompleted !== null && lastCompleted.getTime() === today.getTime();

      return {
        activityId: a.id,
        name: a.name,
        emoji: a.emoji,
        currentStreak: a.currentStreak,
        bestStreak: a.bestStreak,
        completedToday,
        colorHex: a.colorHex,
      };
    });

    return {
      identityId,
      totalActivities: activities.length,
      totalCompletions,
      bestStreak,
      weeklyCompletionRate: Math.round(weeklyRate * 100) / 100,
      activityStats,
    };
  }
}
