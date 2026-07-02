import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '@prisma/client';

export interface DecodedToken {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
}

export async function findOrCreateUser(
  prisma: PrismaService,
  decoded: DecodedToken,
) {
  const firebaseUid = decoded.uid;

  const existing = await prisma.user.findUnique({
    where: { firebaseUid },
  });
  if (existing) return existing;

  try {
    return await prisma.$transaction(async (tx) => {
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
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const user = await prisma.user.findUnique({ where: { firebaseUid } });
      if (user) return user;
    }
    throw error;
  }
}
