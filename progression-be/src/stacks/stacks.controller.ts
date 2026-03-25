import {
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
  async createStack(
    @CurrentUser() user: User,
    @Body() body: { name: string },
  ) {
    return this.stacksService.createStack(user.id, body.name);
  }

  @Post(':id/add')
  async addActivity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { activity_id: string; order?: number },
  ) {
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
    return this.stacksService.removeActivity(user.id, id, body.activity_id);
  }

  @Post(':id/reorder')
  async reorderStack(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { activity_ids: string[] },
  ) {
    return this.stacksService.reorderStack(user.id, id, body.activity_ids);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteStack(@CurrentUser() user: User, @Param('id') id: string) {
    await this.stacksService.deleteStack(user.id, id);
  }
}
