import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common'

import { PrismaPg } from '@prisma/adapter-pg'
import { EnvService } from '@/config/env.service'
import { PrismaClient } from 'generated/prisma/client/client'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name)

  constructor(private readonly env: EnvService) {
    const adapter = new PrismaPg({
      connectionString: env.get('DATABASE_URL'),
    })

    super({
      adapter,
      log: [
        { emit: 'event', level: 'error' },
        { emit: 'event', level: 'warn' },
      ],
    })
  }

  async onModuleInit() {
    await this.$connect()
    this.logger.log('Database connected')

    this.$on('error' as never, (event: any) => {
      this.logger.error(`Database error: ${event.message}`)
    })
  }

  async onModuleDestroy() {
    await this.$disconnect()
    this.logger.log('Database disconnected')
  }
}