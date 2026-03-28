import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  nextFibonacci,
  previousFibonacci,
} from '../common/utils/fibonacci';
import { getUserToday } from '../common/utils/date';

@Injectable()
export class ActivitiesService {
  constructor(private readonly prisma: PrismaService) {}

  async listActivities(userId: string, timezone = 'UTC') {
    const today = getUserToday(timezone);

    const activities = await this.prisma.activity.findMany({
      where: { userId, isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
      include: {
        logs: {
          where: { completedDate: today },
          select: { activityId: true, value: true },
          take: 1,
        },
      },
    });

    return activities.map((a) => {
      const todayLog = a.logs[0];
      const logMap = todayLog
        ? new Map([[todayLog.activityId, { value: todayLog.value }]])
        : new Map();
      const { logs, ...activity } = a;
      return this.buildActivityResponse(activity, today, logMap);
    });
  }

  async createActivity(
    userId: string,
    data: {
      name: string;
      emoji?: string;
      unit?: string;
      baseTarget?: number;
      currentTarget?: number;
      stepSize?: number;
      colorHex?: string;
      sortOrder?: number;
      identityId?: string;
      cueTime?: string;
      cueLocation?: string;
      trackingMode?: string;
    },
  ) {
    const activity = await this.prisma.activity.create({
      data: {
        userId,
        name: data.name,
        emoji: data.emoji ?? '⭐',
        unit: data.unit ?? 'Minutes',
        baseTarget: data.baseTarget ?? 1.0,
        currentTarget: data.currentTarget ?? data.baseTarget ?? 1.0,
        stepSize: data.stepSize ?? 1.0,
        colorHex: data.colorHex ?? '#6C5CE7',
        sortOrder: data.sortOrder ?? 0,
        identityId: data.identityId ?? null,
        cueTime: data.cueTime ?? null,
        cueLocation: data.cueLocation ?? null,
        trackingMode: data.trackingMode ?? 'continuous',
      },
    });
    return this.buildActivityResponse(activity);
  }

  async updateActivity(
    userId: string,
    activityId: string,
    data: Record<string, any>,
    timezone = 'UTC',
  ) {
    const activity = await this.getUserActivity(userId, activityId);

    const updateData: Record<string, any> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.emoji !== undefined) updateData.emoji = data.emoji;
    if (data.colorHex !== undefined) updateData.colorHex = data.colorHex;
    if (data.sortOrder !== undefined) updateData.sortOrder = data.sortOrder;
    if (data.unit !== undefined) updateData.unit = data.unit;
    if (data.identityId !== undefined) updateData.identityId = data.identityId;
    if (data.stackId !== undefined) updateData.stackId = data.stackId;
    if (data.stackOrder !== undefined) updateData.stackOrder = data.stackOrder;
    if (data.cueTime !== undefined) updateData.cueTime = data.cueTime;
    if (data.cueLocation !== undefined) updateData.cueLocation = data.cueLocation;
    if (data.trackingMode !== undefined) updateData.trackingMode = data.trackingMode;

    const today = getUserToday(timezone);

    const updated = await this.prisma.activity.update({
      where: { id: activityId },
      data: updateData,
      include: {
        logs: {
          where: { completedDate: today },
          select: { activityId: true, value: true },
          take: 1,
        },
      },
    });

    const todayLog = updated.logs[0];
    const logMap = todayLog
      ? new Map([[todayLog.activityId, { value: todayLog.value }]])
      : new Map();
    const { logs, ...activityData } = updated;
    return this.buildActivityResponse(activityData, today, logMap);
  }

  async deleteActivity(userId: string, activityId: string) {
    await this.getUserActivity(userId, activityId);
    await this.prisma.activity.update({
      where: { id: activityId },
      data: { isActive: false },
    });
  }

  async togglePause(userId: string, activityId: string) {
    const activity = await this.getUserActivity(userId, activityId);
    const updated = await this.prisma.activity.update({
      where: { id: activityId },
      data: { isPaused: !activity.isPaused },
    });
    return this.buildActivityResponse(updated);
  }

  async countActiveActivities(userId: string): Promise<number> {
    return this.prisma.activity.count({
      where: { userId, isActive: true },
    });
  }

  private async getUserActivity(userId: string, activityId: string) {
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, isActive: true },
    });
    if (!activity) throw new NotFoundException('Activity not found');
    return activity;
  }

  private buildActivityResponse(
    activity: any,
    today?: Date,
    todayLogs?: Map<string, { value: number }>,
  ) {
    if (!today) {
      today = getUserToday('UTC');
    }

    const streak = activity.currentStreak;
    const nextFib = nextFibonacci(streak);
    const prevFib = previousFibonacci(streak);
    const progress =
      streak > 0
        ? (streak - prevFib) / Math.max(1, nextFib - prevFib)
        : 0.0;

    const lastCompleted = activity.lastCompletedDate
      ? new Date(activity.lastCompletedDate)
      : null;
    if (lastCompleted) lastCompleted.setUTCHours(0, 0, 0, 0);
    const completedToday =
      lastCompleted !== null && lastCompleted.getTime() === today.getTime();

    const todayLog = todayLogs?.get(activity.id);
    const valueDoneToday = todayLog?.value ?? 0;

    return {
      ...activity,
      nextMilestone: nextFib,
      prevMilestone: prevFib,
      progressToNext: progress,
      completedToday,
      valueDoneToday,
    };
  }
}
