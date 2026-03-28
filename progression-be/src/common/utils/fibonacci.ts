export const FIBONACCI_CHECKPOINTS: number[] = [
  1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
];

const fibSet = new Set(FIBONACCI_CHECKPOINTS);

export function isFibonacciDay(streak: number): boolean {
  return fibSet.has(streak);
}

export function previousFibonacci(streak: number): number {
  if (streak <= 1) return 0;
  let prev = 0;
  for (const f of FIBONACCI_CHECKPOINTS) {
    if (f < streak) {
      prev = f;
    } else {
      break;
    }
  }
  return prev;
}

/**
 * Get the Fibonacci number at a given index (0-based).
 * Used for cascading activity costs: index 0=0, 1=1, 2=1, 3=2, 4=3, 5=5...
 */
export function fibonacciAt(n: number): number {
  if (n <= 0) return 0;
  if (n === 1) return 1;
  let a = 0, b = 1;
  for (let i = 2; i <= n; i++) {
    [a, b] = [b, a + b];
  }
  return b;
}

export function nextFibonacci(streak: number): number {
  for (const f of FIBONACCI_CHECKPOINTS) {
    if (f > streak) {
      return f;
    }
  }
  return FIBONACCI_CHECKPOINTS[FIBONACCI_CHECKPOINTS.length - 1];
}
