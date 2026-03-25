import Foundation

enum FibonacciHelper {
    static let checkpoints = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377]

    static func isFibonacciDay(_ streak: Int) -> Bool {
        checkpoints.contains(streak)
    }

    static func previousFibonacci(_ streak: Int) -> Int {
        var prev = 0
        for f in checkpoints {
            if f < streak { prev = f } else { break }
        }
        return prev
    }

    static func nextFibonacci(_ streak: Int) -> Int {
        for f in checkpoints {
            if f > streak { return f }
        }
        return checkpoints.last ?? 377
    }

    static func progress(for streak: Int) -> Double {
        guard streak > 0 else { return 0 }
        let prev = previousFibonacci(streak)
        let next = nextFibonacci(streak)
        let range = next - prev
        guard range > 0 else { return 1.0 }
        return Double(streak - prev) / Double(range)
    }
}
