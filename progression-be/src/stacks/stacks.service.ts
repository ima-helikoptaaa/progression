import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class StacksService {
  constructor(private readonly prisma: PrismaService) {}

  async listStacks(userId: string) {
    const stacks = await this.prisma.habitStack.findMany({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'asc' },
      include: {
        activities: {
          where: { isActive: true },
          orderBy: { stackOrder: 'asc' },
          select: { id: true },
        },
      },
    });

    return stacks.map((s) => ({
      id: s.id,
      userId: s.userId,
      name: s.name,
      isActive: s.isActive,
      createdAt: s.createdAt,
      activityIds: s.activities.map((a) => a.id),
    }));
  }

  async createStack(userId: string, name: string) {
    const stack = await this.prisma.habitStack.create({
      data: { userId, name },
    });
    return {
      id: stack.id,
      userId: stack.userId,
      name: stack.name,
      isActive: stack.isActive,
      createdAt: stack.createdAt,
      activityIds: [],
    };
  }

  async addActivity(
    userId: string,
    stackId: string,
    activityId: string,
    order: number,
  ) {
    await this.getUserStack(userId, stackId);

    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, isActive: true },
    });
    if (!activity) throw new NotFoundException('Activity not found');

    await this.prisma.activity.update({
      where: { id: activityId },
      data: { stackId, stackOrder: order },
    });

    return this.getStackResponse(userId, stackId);
  }

  async removeActivity(
    userId: string,
    stackId: string,
    activityId: string,
  ) {
    await this.getUserStack(userId, stackId);

    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, userId, stackId },
    });
    if (!activity) throw new NotFoundException('Activity not in stack');

    await this.prisma.activity.update({
      where: { id: activityId },
      data: { stackId: null, stackOrder: 0 },
    });

    return this.getStackResponse(userId, stackId);
  }

  async reorderStack(
    userId: string,
    stackId: string,
    activityIds: string[],
  ) {
    await this.getUserStack(userId, stackId);

    // Batch all updates in a single transaction
    await this.prisma.$transaction(
      activityIds.map((id, i) =>
        this.prisma.activity.updateMany({
          where: { id, userId, stackId },
          data: { stackOrder: i },
        }),
      ),
    );

    return this.getStackResponse(userId, stackId);
  }

  async deleteStack(userId: string, stackId: string) {
    await this.getUserStack(userId, stackId);

    await this.prisma.$transaction([
      this.prisma.habitStack.update({
        where: { id: stackId },
        data: { isActive: false },
      }),
      this.prisma.activity.updateMany({
        where: { stackId },
        data: { stackId: null, stackOrder: 0 },
      }),
    ]);
  }

  private async getUserStack(userId: string, stackId: string) {
    const stack = await this.prisma.habitStack.findFirst({
      where: { id: stackId, userId, isActive: true },
    });
    if (!stack) throw new NotFoundException('Stack not found');
    return stack;
  }

  private async getStackResponse(userId: string, stackId: string) {
    const stack = await this.prisma.habitStack.findUniqueOrThrow({
      where: { id: stackId },
      include: {
        activities: {
          where: { isActive: true },
          orderBy: { stackOrder: 'asc' },
          select: { id: true },
        },
      },
    });
    return {
      id: stack.id,
      userId: stack.userId,
      name: stack.name,
      isActive: stack.isActive,
      createdAt: stack.createdAt,
      activityIds: stack.activities.map((a) => a.id),
    };
  }
}
