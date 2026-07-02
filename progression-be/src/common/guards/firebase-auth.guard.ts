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
import { findOrCreateUser } from '../utils/user-helper';

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
      throw new UnauthorizedException(
        'Missing or invalid authorization header',
      );
    }

    const token = authHeader.slice(7);
    const decoded = await this.firebase.verifyToken(token);

    const existing = await this.prisma.user.findUnique({
      where: { firebaseUid: decoded.uid },
    });

    if (existing) {
      request.user = existing;
      return true;
    }

    const newUser = await findOrCreateUser(this.prisma, decoded);
    request.user = newUser;
    request.__isNewUser = true;

    return true;
  }
}
