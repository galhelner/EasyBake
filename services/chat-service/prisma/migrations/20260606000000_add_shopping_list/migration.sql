CREATE TABLE "ShoppingListItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ingredientId" TEXT NOT NULL,
    "checked" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ShoppingListItem_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ShoppingListItem_userId_ingredientId_key" ON "ShoppingListItem"("userId", "ingredientId");
CREATE INDEX "ShoppingListItem_userId_idx" ON "ShoppingListItem"("userId");

ALTER TABLE "ShoppingListItem"
ADD CONSTRAINT "ShoppingListItem_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ShoppingListItem"
ADD CONSTRAINT "ShoppingListItem_ingredientId_fkey"
FOREIGN KEY ("ingredientId") REFERENCES "Ingredient"("id") ON DELETE RESTRICT ON UPDATE CASCADE;