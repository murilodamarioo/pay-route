import { Module } from '@nestjs/common'
import { TerminusModule } from '@nestjs/terminus'
import { HttpModule } from '@nestjs/axios'

import { EnvModule } from '@/config/env.module'

import { HealthController } from './health.controller'

@Module({
  imports: [TerminusModule, HttpModule, EnvModule],
  controllers: [HealthController]
})
export class HealthModule { }
