-- AlterTable
ALTER TABLE "Message"
ADD COLUMN "messageType" TEXT NOT NULL DEFAULT 'text',
ADD COLUMN "recipeId" TEXT;
