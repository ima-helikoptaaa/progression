import { Body, Controller, Get, Put } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentUser() user: User) {
    return user;
  }

  @Put('me')
  async updateMe(
    @CurrentUser() user: User,
    @Body() body: { display_name?: string; timezone?: string },
  ) {
    return this.usersService.updateMe(user.id, {
      displayName: body.display_name,
      timezone: body.timezone,
    });
  }
}
