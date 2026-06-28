import {
  Controller,
  Get,
  HttpCode,
  HttpStatus
} from '@nestjs/common'
import {
  HealthCheck,
  HealthCheckService,
  HttpHealthIndicator,
} from '@nestjs/terminus'

import { EnvService } from '@/config/env.service'

@Controller()
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private env: EnvService
  ) { }

  @Get()
  @HttpCode(HttpStatus.OK)
  @Get('health')
  @HttpCode(HttpStatus.OK)
  @HealthCheck()
  check() {
    const port = this.env.get('PORT')

    return this.health.check([
      () => this.http.pingCheck('Application', `http://127.0.0.1:${port}/`),
    ])
  }
}
