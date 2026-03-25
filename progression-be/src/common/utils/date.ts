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
    // Invalid timezone — fall back to UTC
    const d = new Date();
    d.setUTCHours(0, 0, 0, 0);
    return d;
  }
}

export function getUserYesterday(timezone: string): Date {
  const today = getUserToday(timezone);
  today.setUTCDate(today.getUTCDate() - 1);
  return today;
}

/**
 * Calculate number of full days between two dates (date-only, no time component).
 */
export function daysBetween(a: Date, b: Date): number {
  const msPerDay = 86_400_000;
  return Math.floor(Math.abs(b.getTime() - a.getTime()) / msPerDay);
}
