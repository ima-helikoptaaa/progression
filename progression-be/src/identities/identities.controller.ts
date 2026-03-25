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
  Put,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '@prisma/client';
import { IdentitiesService } from './identities.service';

const COLOR_HEX_REGEX = /^#[0-9A-Fa-f]{6}$/;

@Controller('identities')
export class IdentitiesController {
  constructor(private readonly identitiesService: IdentitiesService) {}

  @Get()
  async listIdentities(@CurrentUser() user: User) {
    return this.identitiesService.listIdentities(user.id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createIdentity(
    @CurrentUser() user: User,
    @Body()
    body: {
      name: string;
      emoji?: string;
      color_hex?: string;
      sort_order?: number;
    },
  ) {
    if (!body.name || body.name.trim().length === 0) {
      throw new BadRequestException('Identity name is required');
    }
    if (body.name.trim().length > 30) {
      throw new BadRequestException(
        'Identity name must be 30 characters or less',
      );
    }
    if (
      body.color_hex !== undefined &&
      !COLOR_HEX_REGEX.test(body.color_hex)
    ) {
      throw new BadRequestException(
        'Color must be a valid hex code (e.g., #6C5CE7)',
      );
    }

    return this.identitiesService.createIdentity(user.id, {
      name: body.name.trim(),
      emoji: body.emoji,
      colorHex: body.color_hex,
      sortOrder: body.sort_order,
    });
  }

  @Put(':id')
  async updateIdentity(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      emoji?: string;
      color_hex?: string;
      sort_order?: number;
    },
  ) {
    if (body.name !== undefined && body.name.trim().length === 0) {
      throw new BadRequestException('Identity name cannot be empty');
    }
    if (body.name !== undefined && body.name.trim().length > 30) {
      throw new BadRequestException(
        'Identity name must be 30 characters or less',
      );
    }
    if (
      body.color_hex !== undefined &&
      !COLOR_HEX_REGEX.test(body.color_hex)
    ) {
      throw new BadRequestException(
        'Color must be a valid hex code (e.g., #6C5CE7)',
      );
    }

    return this.identitiesService.updateIdentity(user.id, id, {
      name: body.name?.trim(),
      emoji: body.emoji,
      colorHex: body.color_hex,
      sortOrder: body.sort_order,
    });
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteIdentity(@CurrentUser() user: User, @Param('id') id: string) {
    await this.identitiesService.deleteIdentity(user.id, id);
  }
}
