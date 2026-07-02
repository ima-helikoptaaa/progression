import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { PenaltyService } from '../activities/penalty.service';

@Processor('penalties')
export class PenaltyProcessor extends WorkerHost {
  private readonly logger = new Logger(PenaltyProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly penaltyService: PenaltyService,
  ) {
    super();
  }

  async process(job: Job): Promise<void> {
    this.logger.log(`Running daily penalty check job: ${job.id}`);

    const users = await this.prisma.user.findMany({
      select: { id: true, timezone: true },
    });

    let totalPenalties = 0;
    let totalPointsDeducted = 0;

    for (const user of users) {
      try {
        const result = await this.penaltyService.checkAndApplyPenalties(
          this.prisma,
          user.id,
          user.timezone,
        );
        totalPenalties += result.penalties.length;
        totalPointsDeducted += result.pointsDeducted;
      } catch (err) {
        this.logger.error(
          `Failed to process penalties for user ${user.id}`,
          err,
        );
      }
    }

    this.logger.log(
      `Penalty job complete: ${users.length} users, ${totalPenalties} penalties, ${totalPointsDeducted} points deducted`,
    );
  }
}
