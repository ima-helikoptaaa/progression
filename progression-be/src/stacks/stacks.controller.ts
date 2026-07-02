import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { StacksService } from './stacks.service';

@Controller('stacks')
export class StacksController {
  constructor(private readonly stacksService: StacksService) {}

  @Get()
  async listStacks(@CurrentUser() user: User) {
    return this.stacksService.listStacks(user.id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createStack(@CurrentUser() user: User, @Body() body: { name: string }) {
    if (!body.name || body.name.trim().length === 0) {
      throw new BadRequestException('Stack name is required');
    }
    if (body.name.trim().length > 100) {
      throw new BadRequestException(
        'Stack name must be 100 characters or less',
      );
    }
    return this.stacksService.createStack(user.id, body.name.trim());
  }

  @Post(':id/add')
  async addActivity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { activity_id: string; order?: number },
  ) {
    if (!body.activity_id) {
      throw new BadRequestException('activity_id is required');
    }
    return this.stacksService.addActivity(
      user.id,
      id,
      body.activity_id,
      body.order ?? 0,
    );
  }

  @Post(':id/remove')
  async removeActivity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { activity_id: string },
  ) {
    if (!body.activity_id) {
      throw new BadRequestException('activity_id is required');
    }
    return this.stacksService.removeActivity(user.id, id, body.activity_id);
  }

  @Post(':id/reorder')
  async reorderStack(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { activity_ids: string[] },
  ) {
    if (!Array.isArray(body.activity_ids)) {
      throw new BadRequestException('activity_ids must be an array');
    }
    return this.stacksService.reorderStack(user.id, id, body.activity_ids);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteStack(@CurrentUser() user: User, @Param('id') id: string) {
    await this.stacksService.deleteStack(user.id, id);
  }
}
