import { Module } from '@nestjs/common'

import { HealthController } from './health.controller'
import { HealthService } from './health.service'
import { EnvModule } from '@/config/env.module'

@Module({
  imports: [EnvModule],
  controllers: [HealthController],
  providers: [HealthService]
})
export class HealthModule { }
