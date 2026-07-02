import { Injectable } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { PrismaService } from '../prisma/prisma.service';
import { findOrCreateUser } from '../common/utils/user-helper';

@Injectable()
export class AuthService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly prisma: PrismaService,
  ) {}

  async login(idToken: string, timezone?: string) {
    const decoded = await this.firebase.verifyToken(idToken);
    const user = await findOrCreateUser(this.prisma, decoded);

    if (timezone && timezone !== user.timezone) {
      const updated = await this.prisma.user.update({
        where: { id: user.id },
        data: { timezone },
      });
      return updated;
    }

    return user;
  }
}
