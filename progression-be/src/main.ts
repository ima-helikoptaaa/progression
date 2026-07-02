import { NestFactory } from '@nestjs/core';
import {
  RequestMethod,
  ValidationPipe,
  HttpException,
  HttpStatus,
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  Logger,
} from '@nestjs/common';
import { AppModule } from './app.module';
import { Prisma } from '@prisma/client';

@Catch()
class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
      } else if (Array.isArray((res as any).message)) {
        message = (res as any).message.join(', ');
      } else {
        message = (res as any).message ?? message;
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        message = 'Resource not found';
      } else if (exception.code === 'P2002') {
        status = HttpStatus.CONFLICT;
        message = 'Resource already exists';
      } else {
        this.logger.error(`Prisma error ${exception.code}`, exception.stack);
      }
    } else {
      this.logger.error(
        'Unhandled exception',
        exception instanceof Error ? exception.stack : exception,
      );
    }

    response.status(status).json({
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const origins =
    process.env.CORS_ORIGINS?.split(',')
      .map((o) => o.trim())
      .filter(Boolean) ?? [];
  app.enableCors({
    origin: origins.length > 0 ? origins : false,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Api-Key'],
  });

  app.setGlobalPrefix('api/v1', {
    exclude: [{ path: 'health', method: RequestMethod.GET }],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
    }),
  );

  app.useGlobalFilters(new GlobalExceptionFilter());

  app.enableShutdownHooks();

  const port = process.env.PORT ?? 8000;
  await app.listen(port);
  Logger.log(`Application running on port ${port}`, 'Bootstrap');
}
bootstrap();
