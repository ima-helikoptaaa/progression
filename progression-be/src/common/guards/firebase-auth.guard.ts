import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { FirebaseService } from '../../firebase/firebase.service';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly firebase: FirebaseService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization header');
    }

    const token = authHeader.slice(7);
    const decoded = await this.firebase.verifyToken(token);
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
      request.user = user;
      (request as any).__isNewUser = true;
    } else {
      request.user = user;
    }

    return true;
  }
}
