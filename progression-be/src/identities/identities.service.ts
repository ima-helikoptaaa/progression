import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const MAX_IDENTITIES = 3;

@Injectable()
export class IdentitiesService {
  constructor(private readonly prisma: PrismaService) {}

  async listIdentities(userId: string) {
    return this.prisma.identity.findMany({
      where: { userId, isActive: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async createIdentity(
    userId: string,
    data: { name: string; emoji?: string; colorHex?: string; sortOrder?: number },
  ) {
    const count = await this.prisma.identity.count({
      where: { userId, isActive: true },
    });
    if (count >= MAX_IDENTITIES) {
      throw new BadRequestException(
        `Maximum ${MAX_IDENTITIES} identities allowed`,
      );
    }

    return this.prisma.identity.create({
      data: {
        userId,
        name: data.name,
        emoji: data.emoji ?? '🎯',
        colorHex: data.colorHex ?? '#6C5CE7',
        sortOrder: data.sortOrder ?? 0,
      },
    });
  }

  async updateIdentity(
    userId: string,
    identityId: string,
    data: Record<string, any>,
  ) {
    const identity = await this.getUserIdentity(userId, identityId);
    const updateData: Record<string, any> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.emoji !== undefined) updateData.emoji = data.emoji;
    if (data.colorHex !== undefined) updateData.colorHex = data.colorHex;
    if (data.sortOrder !== undefined) updateData.sortOrder = data.sortOrder;

    return this.prisma.identity.update({
      where: { id: identityId },
      data: updateData,
    });
  }

  async deleteIdentity(userId: string, identityId: string) {
    await this.getUserIdentity(userId, identityId);

    await this.prisma.$transaction([
      this.prisma.identity.update({
        where: { id: identityId },
        data: { isActive: false },
      }),
      this.prisma.activity.updateMany({
        where: { identityId },
        data: { identityId: null },
      }),
    ]);
  }

  private async getUserIdentity(userId: string, identityId: string) {
    const identity = await this.prisma.identity.findFirst({
      where: { id: identityId, userId, isActive: true },
    });
    if (!identity) throw new NotFoundException('Identity not found');
    return identity;
  }
}
