-- Add displayName column to User and backfill from fullName
-- Non-destructive: adds nullable column and updates existing rows

ALTER TABLE "User"
ADD COLUMN IF NOT EXISTS "displayName" TEXT;

-- Backfill existing users where displayName is null
UPDATE "User"
SET "displayName" = "fullName"
WHERE "displayName" IS NULL;

-- Optional: keep the column nullable; if you prefer non-null with default, handle carefully in production
