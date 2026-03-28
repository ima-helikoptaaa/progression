import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';

@Injectable()
export class PenaltyScheduler implements OnModuleInit {
  private readonly logger = new Logger(PenaltyScheduler.name);

  constructor(@InjectQueue('penalties') private readonly penaltyQueue: Queue) {}

  async onModuleInit() {
    // Remove any old repeatable jobs first to avoid duplicates
    const existing = await this.penaltyQueue.getRepeatableJobs();
    for (const job of existing) {
      await this.penaltyQueue.removeRepeatableByKey(job.key);
    }

    // Schedule daily penalty check at 5:29 AM UTC
    await this.penaltyQueue.add(
      'daily-penalty-check',
      {},
      {
        repeat: {
          pattern: '29 5 * * *', // 5:29 AM every day
        },
        removeOnComplete: { count: 10 },
        removeOnFail: { count: 50 },
      },
    );

    this.logger.log('Scheduled daily penalty check at 5:29 AM UTC');
  }
}
