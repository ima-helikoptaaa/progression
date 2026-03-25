export const FIBONACCI_CHECKPOINTS: number[] = [
  1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377,
];

const fibSet = new Set(FIBONACCI_CHECKPOINTS);

export function isFibonacciDay(streak: number): boolean {
  return fibSet.has(streak);
}

export function previousFibonacci(streak: number): number {
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

export function nextFibonacci(streak: number): number {
  for (const f of FIBONACCI_CHECKPOINTS) {
    if (f > streak) {
      return f;
    }
  }
  return FIBONACCI_CHECKPOINTS[FIBONACCI_CHECKPOINTS.length - 1];
}
