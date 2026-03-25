import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(userId: string) {
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

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekStart = new Date(today);
    weekStart.setDate(weekStart.getDate() - today.getDay());
    // Python uses Monday as weekday 0 (today.weekday()), JS getDay() uses Sunday=0
    // Python: week_start = today - timedelta(days=today.weekday())
    // This means Monday-based week. Let's match that.
    const dayOfWeek = today.getDay(); // 0=Sun, 1=Mon, ...
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    weekStart.setDate(today.getDate() - mondayOffset);

    const prevWeekStart = new Date(weekStart);
    prevWeekStart.setDate(prevWeekStart.getDate() - 7);

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

  async getHeatmap(userId: string, days: number = 90) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - days);

    const totalActivities = await this.prisma.activity.count({
      where: { userId, isActive: true, isPaused: false },
    });
    const denominator = Math.max(totalActivities, 1);

    const logs = await this.prisma.activityLog.groupBy({
      by: ['completedDate'],
      where: { userId, completedDate: { gte: startDate } },
      _count: { id: true },
      _sum: { completionCount: true },
      orderBy: { completedDate: 'asc' },
    });

    const entries = logs.map((row) => {
      const count = row._count.id;
      const totalCompletions = row._sum.completionCount ?? count;
      const baseRatio = Math.min(1.0, count / denominator);
      const overchargeBoost = Math.min(
        1.0,
        totalCompletions / Math.max(1, denominator * 2),
      );
      const intensity = Math.min(1.0, baseRatio * 0.7 + overchargeBoost * 0.3);

      return {
        date: row.completedDate,
        count,
        ratio: baseRatio,
        totalCompletions,
        intensity,
      };
    });

    return { entries, totalActivities: denominator };
  }

  async getActivityHistory(
    userId: string,
    activityId: string,
    days: number = 30,
  ) {
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId },
    });
    if (!activity) throw new NotFoundException('Activity not found');

    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0);
    startDate.setDate(startDate.getDate() - days);

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

  async getIdentityStats(userId: string, identityId: string) {
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

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dayOfWeek = today.getDay();
    const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const weekStart = new Date(today);
    weekStart.setDate(today.getDate() - mondayOffset);

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
      if (lastCompleted) lastCompleted.setHours(0, 0, 0, 0);
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
