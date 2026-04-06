ALTER TABLE "Ingredient"
ALTER COLUMN "icon" SET DEFAULT '';

UPDATE "Ingredient"
SET "icon" = ''
WHERE "icon" = '🥘';
