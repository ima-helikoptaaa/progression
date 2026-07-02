/**
 * Get "today" as a midnight-UTC Date for the user's timezone.
 * PostgreSQL DATE columns store date-only, so midnight-UTC aligns correctly.
 */
export function getUserToday(timezone: string): Date {
  try {
    const dateStr = new Date().toLocaleDateString('en-CA', {
      timeZone: timezone,
    });
    return new Date(dateStr + 'T00:00:00.000Z');
  } catch {
    const d = new Date();
    d.setUTCHours(0, 0, 0, 0);
    return d;
  }
}

export function getUserYesterday(timezone: string): Date {
  const today = getUserToday(timezone);
  const yesterday = new Date(today);
  yesterday.setUTCDate(today.getUTCDate() - 1);
  return yesterday;
}

/**
 * Calculate number of full days between two dates (date-only, no time component).
 * Returns 0 if b is before or equal to a (never negative).
 */
export function daysBetween(a: Date, b: Date): number {
  const msPerDay = 86_400_000;
  const diff = b.getTime() - a.getTime();
  if (diff <= 0) return 0;
  return Math.floor(diff / msPerDay);
}
