import { Injectable, OnModuleInit, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import * as fs from 'fs';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private app!: admin.app.App;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    if (admin.apps.length > 0) {
      this.app = admin.apps[0]!;
      return;
    }

    const credPath = this.config.get<string>(
      'FIREBASE_CREDENTIALS_PATH',
      './firebase-service-account.json',
    );
    const credJson = this.config.get<string>('FIREBASE_CREDENTIALS_JSON', '');

    if (fs.existsSync(credPath)) {
      const cred = admin.credential.cert(credPath);
      this.app = admin.initializeApp({ credential: cred });
    } else if (credJson) {
      const credDict = JSON.parse(credJson);
      const cred = admin.credential.cert(credDict);
      this.app = admin.initializeApp({ credential: cred });
    } else {
      this.app = admin.initializeApp();
    }
  }

  async verifyToken(
    idToken: string,
  ): Promise<admin.auth.DecodedIdToken> {
    try {
      return await this.app.auth().verifyIdToken(idToken);
    } catch (error: any) {
      const code = error?.code ?? error?.errorInfo?.code ?? '';
      if (
        code === 'auth/id-token-expired' ||
        code === 'auth/argument-error' ||
        error?.message?.includes('expired')
      ) {
        throw new UnauthorizedException(
          'Token expired. Please sign in again.',
        );
      }
      throw new UnauthorizedException(
        'Invalid authentication token.',
      );
    }
  }
}
