import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { StreakService } from '../../activities/streak.service';

// Track which users have already had penalties checked in recent time window
const recentlyChecked = new Map<string, number>();
const CHECK_INTERVAL_MS = 60_000; // Only check once per minute per user

@Injectable()
export class PenaltyCheckInterceptor implements NestInterceptor {
  constructor(
    private readonly reflector: Reflector,
    private readonly streakService: StreakService,
  ) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<any>> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return next.handle();

    const request = context.switchToHttp().getRequest();
    const isNewUser = (request as any).__isNewUser;
    if (isNewUser) return next.handle();

    // Skip if this IS the penalties endpoint (it handles its own check)
    const url = request.url ?? '';
    if (url.includes('/penalties')) return next.handle();

    const user = request.user;
    if (user) {
      const now = Date.now();
      const lastChecked = recentlyChecked.get(user.id);

      // Only run penalty check once per minute per user to prevent
      // double-application from concurrent requests
      if (!lastChecked || now - lastChecked > CHECK_INTERVAL_MS) {
        recentlyChecked.set(user.id, now);
        await this.streakService.checkAndApplyPenalties(user.id);

        // Clean up old entries periodically
        if (recentlyChecked.size > 1000) {
          for (const [key, time] of recentlyChecked) {
            if (now - time > CHECK_INTERVAL_MS * 5) {
              recentlyChecked.delete(key);
            }
          }
        }
      }
    }

    return next.handle();
  }
}
