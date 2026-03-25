import { Injectable } from '@nestjs/common';
import { FirebaseService } from '../firebase/firebase.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly prisma: PrismaService,
  ) {}

  async login(idToken: string) {
    const decoded = await this.firebase.verifyToken(idToken);
    const firebaseUid = decoded.uid;

    let user = await this.prisma.user.findUnique({
      where: { firebaseUid },
    });

    if (!user) {
      user = await this.prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            firebaseUid,
            email: decoded.email ?? '',
            displayName: decoded.name ?? null,
            photoUrl: decoded.picture ?? null,
            totalPoints: 1,
            lifetimePoints: 1,
          },
        });
        await tx.pointTransaction.create({
          data: {
            userId: newUser.id,
            amount: 1,
            transactionType: 'welcome',
            description: 'Welcome bonus point',
          },
        });
        return newUser;
      });
    }

    return user;
  }
}
