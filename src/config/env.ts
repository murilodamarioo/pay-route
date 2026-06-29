import z from 'zod'

export const envSchema = z.object({
  NODE_ENV: z.enum(['prod', 'test', 'dev']).default('dev'),
  PORT: z.coerce.number().optional().default(3000),
  DATABASE_URL: z.string(),
  REDIS_URL: z.string(),
  JWT_SECRET: z.string(),
  NPM_PACKAGE_VERSION: z.string()
})

export type Env = z.infer<typeof envSchema>