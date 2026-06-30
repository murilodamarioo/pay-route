import { Module } from '@nestjs/common'
import { PrismaService } from './prisma/prisma.service'
import { EnvModule } from '@/config/env.module'

@Module({
  imports: [EnvModule],
  providers: [PrismaService],
  exports: [PrismaService]
})
export class DatabaseModule { }