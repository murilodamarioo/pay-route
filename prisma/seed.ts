import 'dotenv/config'
import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient, AcquirerCode, CircuitState } from 'generated/prisma/client/client'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
})

const prisma = new PrismaClient({ adapter })

async function main() {
  console.log('🌱 Iniciando seed...')

  // ─── ACQUIRERS ──────────────────────────────────────────────────────────────

  const cielo = await prisma.acquirer.upsert({
    where: { code: AcquirerCode.CIELO },
    update: {},
    create: {
      name: 'Cielo S.A.',
      code: AcquirerCode.CIELO,
      isActive: true,
      priority: 1,
      feePercentage: 0.0199,
      feeFixed: 0.0,
      maxTimeout: 5000,
    },
  })

  const stone = await prisma.acquirer.upsert({
    where: { code: AcquirerCode.STONE },
    update: {},
    create: {
      name: 'Stone Pagamentos S.A.',
      code: AcquirerCode.STONE,
      isActive: true,
      priority: 2,
      feePercentage: 0.021,
      feeFixed: 0.0,
      maxTimeout: 4000,
    },
  })

  const adyen = await prisma.acquirer.upsert({
    where: { code: AcquirerCode.ADYEN },
    update: {},
    create: {
      name: 'Adyen N.V.',
      code: AcquirerCode.ADYEN,
      isActive: true,
      priority: 3,
      feePercentage: 0.025,
      feeFixed: 0.11,
      maxTimeout: 6000,
    },
  })

  console.log('✅ Adquirentes criados:', { cielo: cielo.id, stone: stone.id, adyen: adyen.id })

  // ─── ACQUIRER HEALTH ────────────────────────────

  const now = new Date()
  const windowStart = new Date(now.getTime() - 15 * 60 * 1000)

  for (const acquirer of [cielo, stone, adyen]) {
    await prisma.acquirerHealth.create({
      data: {
        acquirerId: acquirer.id,
        approvalRate: 0.95,
        avgLatencyMs: 200,
        errorRate: 0.005,
        p95LatencyMs: 350,
        totalSamples: 0,
        circuitState: CircuitState.CLOSED,
        isHealthy: true,
        lastCheckedAt: now,
        windowStart,
      },
    })
  }

  console.log('✅ Health inicial dos adquirentes criado')

  // ─── ROUTING RULES ────────────────────────────────────────────────────────

  await prisma.routingRule.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Alto valor → Cielo',
      description: 'Transações acima de R$5.000 são processadas pela Cielo por ter menor taxa para este volume.',
      priority: 1,
      isActive: true,
      conditions: { amount_gt: 500000 },
      targetAcquirerId: cielo.id,
    },
  })

  await prisma.routingRule.upsert({
    where: { id: '00000000-0000-0000-0000-000000000002' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000002',
      name: 'AMEX → Adyen',
      description: 'Cartões American Express têm melhor taxa de aprovação na Adyen.',
      priority: 2,
      isActive: true,
      conditions: { card_brand_eq: 'AMEX' },
      targetAcquirerId: adyen.id,
    },
  })

  await prisma.routingRule.upsert({
    where: { id: '00000000-0000-0000-0000-000000000003' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Internacional → Adyen',
      description: 'Clientes fora do Brasil têm melhor aprovação via Adyen.',
      priority: 3,
      isActive: true,
      conditions: { customer_country_neq: 'BR' },
      targetAcquirerId: adyen.id,
    },
  })

  await prisma.routingRule.upsert({
    where: { id: '00000000-0000-0000-0000-000000000004' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000004',
      name: 'Ticket baixo → Stone',
      description: 'Transações abaixo de R$50 têm custo menor na Stone (sem taxa fixa).',
      priority: 4,
      isActive: false,
      conditions: { amount_lt: 5000 },
      targetAcquirerId: stone.id,
    },
  })

  console.log('✅ Regras de roteamento criadas')
  console.log('🎉 Seed concluído com sucesso!')
}

main()
  .catch((error) => {
    console.error('❌ Erro no seed:', error)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })