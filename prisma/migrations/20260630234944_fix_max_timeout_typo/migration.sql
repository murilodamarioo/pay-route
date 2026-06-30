/*
  Warnings:

  - You are about to drop the column `max_timout` on the `acquirers` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "acquirers" DROP COLUMN "max_timout",
ADD COLUMN     "max_timeout" INTEGER NOT NULL DEFAULT 5000;
