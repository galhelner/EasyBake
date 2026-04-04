DO $$
BEGIN
  ALTER TABLE "User"
  ADD CONSTRAINT "User_email_key" UNIQUE ("email");
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
