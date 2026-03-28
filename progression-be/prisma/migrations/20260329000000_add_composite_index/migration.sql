-- CreateIndex
CREATE INDEX "activity_logs_user_id_completed_date_idx" ON "activity_logs"("user_id", "completed_date");
