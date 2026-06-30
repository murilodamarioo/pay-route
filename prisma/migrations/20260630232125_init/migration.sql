-- CreateEnum
CREATE TYPE "TransactionStatus" AS ENUM ('PENDING', 'APPROVED', 'DECLINED', 'ERROR', 'FALLBACK');

-- CreateEnum
CREATE TYPE "AcquirerCode" AS ENUM ('CIELO', 'STONE', 'ADYEN', 'STRIPE');

-- CreateEnum
CREATE TYPE "CircuitState" AS ENUM ('CLOSED', 'OPEN', 'HALF_OPEN');

-- CreateEnum
CREATE TYPE "TransactionEventType" AS ENUM ('CREATED', 'ROUTING_DECIDED', 'ACQUIRER_CALLED', 'ACQUIRER_RESPONDED', 'FALLBACK_TRIGGERED', 'STATUS_CHANGED', 'CAPTURE_REQUESTED', 'CAPTURE_COMPLETED', 'CANCELLATION_REQUESTED', 'CANCELLATION_COMPLETED', 'WEBHOOK_SENT', 'WEBHOOK_FAILED');

-- CreateEnum
CREATE TYPE "CardBrand" AS ENUM ('VISA', 'MASTERCARD', 'ELO', 'AMEX', 'HIPERCARD', 'UNKNOWN');

-- CreateTable
CREATE TABLE "acquirers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(100) NOT NULL,
    "code" "AcquirerCode" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "priority" INTEGER NOT NULL DEFAULT 1,
    "fee_percentage" DECIMAL(5,4) NOT NULL,
    "fee_fixed" DECIMAL(10,2) NOT NULL,
    "max_timout" INTEGER NOT NULL DEFAULT 5000,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "acquirers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acquirer_health" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "acquirer_id" UUID NOT NULL,
    "approval_rate" DECIMAL(5,4) NOT NULL,
    "avg_latency_ms" INTEGER NOT NULL,
    "error_rate" DECIMAL(5,4) NOT NULL,
    "p95_latency_ms" INTEGER NOT NULL DEFAULT 0,
    "total_samples" INTEGER NOT NULL DEFAULT 0,
    "circuit_state" "CircuitState" NOT NULL DEFAULT 'CLOSED',
    "is_healthy" BOOLEAN NOT NULL DEFAULT true,
    "last_checked_at" TIMESTAMPTZ NOT NULL,
    "window_start" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "acquirer_health_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "routing_rules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "priority" INTEGER NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "conditions" JSONB NOT NULL,
    "target_acquirer_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "routing_rules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "external_id" VARCHAR(255) NOT NULL,
    "idempotency_key" VARCHAR(255),
    "amount" INTEGER NOT NULL,
    "currency" CHAR(3) NOT NULL DEFAULT 'BRL',
    "status" "TransactionStatus" NOT NULL DEFAULT 'PENDING',
    "card_last_four" CHAR(4),
    "card_brand" "CardBrand" DEFAULT 'UNKNOWN',
    "card_holder_name" VARCHAR(200),
    "acquirer_id" UUID,
    "routing_rule_id" UUID,
    "fallback_count" INTEGER NOT NULL DEFAULT 0,
    "acquirer_transaction_id" VARCHAR(255),
    "latency_ms" INTEGER,
    "acquirer_latency_ms" INTEGER,
    "metadata" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,
    "processed_at" TIMESTAMPTZ,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction_events" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "transaction_id" UUID NOT NULL,
    "type" "TransactionEventType" NOT NULL,
    "status_before" "TransactionStatus",
    "status_after" "TransactionStatus",
    "acquirer_code" "AcquirerCode",
    "payload" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transaction_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "acquirers_code_key" ON "acquirers"("code");

-- CreateIndex
CREATE INDEX "acquirer_health_acquirer_id_last_checked_at_idx" ON "acquirer_health"("acquirer_id", "last_checked_at" DESC);

-- CreateIndex
CREATE INDEX "routing_rules_is_active_priority_idx" ON "routing_rules"("is_active", "priority" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "transactions_idempotency_key_key" ON "transactions"("idempotency_key");

-- CreateIndex
CREATE INDEX "transactions_status_created_at_idx" ON "transactions"("status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "transactions_acquirer_id_created_at_idx" ON "transactions"("acquirer_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "transactions_external_id_idx" ON "transactions"("external_id");

-- CreateIndex
CREATE INDEX "transactions_idempotency_key_idx" ON "transactions"("idempotency_key");

-- CreateIndex
CREATE INDEX "transaction_events_transaction_id_created_at_idx" ON "transaction_events"("transaction_id", "created_at" ASC);

-- AddForeignKey
ALTER TABLE "acquirer_health" ADD CONSTRAINT "acquirer_health_acquirer_id_fkey" FOREIGN KEY ("acquirer_id") REFERENCES "acquirers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "routing_rules" ADD CONSTRAINT "routing_rules_target_acquirer_id_fkey" FOREIGN KEY ("target_acquirer_id") REFERENCES "acquirers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_acquirer_id_fkey" FOREIGN KEY ("acquirer_id") REFERENCES "acquirers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_routing_rule_id_fkey" FOREIGN KEY ("routing_rule_id") REFERENCES "routing_rules"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction_events" ADD CONSTRAINT "transaction_events_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transactions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
