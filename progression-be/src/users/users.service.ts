import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    return this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
  }

  async updateMe(
    userId: string,
    data: { displayName?: string; timezone?: string },
  ) {
    const updateData: Record<string, any> = {};
    if (data.displayName !== undefined) updateData.displayName = data.displayName;
    if (data.timezone !== undefined) updateData.timezone = data.timezone;

    return this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });
  }
}
