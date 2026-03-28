import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { timingSafeEqual } from 'crypto';

@Injectable()
export class ApiKeyGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const apiKey = request.headers['x-api-key'];
    const expectedKey = this.config.get<string>('AGENT_API_KEY');

    if (!expectedKey) {
      throw new UnauthorizedException('Agent API key not configured');
    }

    if (
      !apiKey ||
      typeof apiKey !== 'string' ||
      apiKey.length !== expectedKey.length ||
      !timingSafeEqual(Buffer.from(apiKey), Buffer.from(expectedKey))
    ) {
      throw new UnauthorizedException('Invalid API key');
    }

    return true;
  }
}
