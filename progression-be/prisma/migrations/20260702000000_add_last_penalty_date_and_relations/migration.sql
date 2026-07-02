-- AlterTable: Add lastPenaltyDate column
ALTER TABLE "activities" ADD COLUMN "last_penalty_date" DATE;

-- Update default colors from purple to orange
UPDATE "activities" SET "color_hex" = '#FF6B35' WHERE "color_hex" = '#6C5CE7';
UPDATE "identities" SET "color_hex" = '#FF6B35' WHERE "color_hex" = '#6C5CE7';

ALTER TABLE "activities" ALTER COLUMN "color_hex" SET DEFAULT '#FF6B35';
ALTER TABLE "identities" ALTER COLUMN "color_hex" SET DEFAULT '#FF6B35';

-- Add foreign key constraints for user_id references
ALTER TABLE "activity_logs" ADD CONSTRAINT "activity_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "streak_history" ADD CONSTRAINT "streak_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
