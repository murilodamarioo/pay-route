import { EnvService } from '@/config/env.service'
import { Injectable } from '@nestjs/common'

@Injectable()
export class HealthService {
  private readonly startTime = Date.now()

  constructor(private readonly config: EnvService) { }

  check() {
    const version = this.config.get('NPM_PACKAGE_VERSION')
    const environment = this.config.get('NODE_ENV')

    return {
      status: 'ok',
      version,
      uptime: Math.floor((Date.now() - this.startTime) / 1000),
      timestamp: new Date().toISOString(),
      environment
    }
  }
}