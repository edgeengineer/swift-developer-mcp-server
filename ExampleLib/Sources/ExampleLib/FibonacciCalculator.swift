import Foundation

/// An async Fibonacci calculator with caching and debug capabilities
public actor FibonacciCalculator {
    private var cache: [Int: UInt64] = [:]
    private var calculationCount: Int = 0
    
    public init() {}
    
    /// Calculate the nth Fibonacci number asynchronously
    /// - Parameter n: The position in the Fibonacci sequence (0-based)
    /// - Returns: The Fibonacci number at position n
    /// - Throws: `FibonacciError.invalidInput` if n is negative
    public func calculate(_ n: Int) async throws -> UInt64 {
        guard n >= 0 else {
            throw FibonacciError.invalidInput("Position must be non-negative, got: \(n)")
        }
        
        calculationCount += 1
        
        // Check cache first
        if let cached = cache[n] {
            print("Cache hit for position \(n): \(cached)")
            return cached
        }
        
        // Base cases
        if n <= 1 {
            let result = UInt64(n)
            cache[n] = result
            print("Base case for position \(n): \(result)")
            return result
        }
        
        // Recursive case with async delay to simulate work
        print("Calculating Fibonacci for position \(n)...")
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
        
        let prev1 = try await calculate(n - 1)
        let prev2 = try await calculate(n - 2)
        let result = prev1 + prev2
        
        cache[n] = result
        print("Calculated Fibonacci for position \(n): \(result)")
        
        return result
    }
    
    /// Calculate multiple Fibonacci numbers concurrently
    /// - Parameter positions: Array of positions to calculate
    /// - Returns: Dictionary mapping positions to their Fibonacci values
    public func calculateMultiple(_ positions: [Int]) async throws -> [Int: UInt64] {
        let tasks = positions.map { position in
            Task {
                let result = try await calculate(position)
                return (position, result)
            }
        }
        
        var results: [Int: UInt64] = [:]
        for task in tasks {
            let (position, value) = try await task.value
            results[position] = value
        }
        
        return results
    }
    
    /// Get the current cache state
    public func getCacheState() -> [Int: UInt64] {
        return cache
    }
    
    /// Get the total number of calculations performed
    public func getCalculationCount() -> Int {
        return calculationCount
    }
    
    /// Clear the cache
    public func clearCache() {
        cache.removeAll()
        print("Cache cleared")
    }
    
    /// Generate Fibonacci sequence up to position n
    /// - Parameter maxPosition: Maximum position to calculate
    /// - Returns: Array of Fibonacci numbers from 0 to maxPosition
    public func generateSequence(upTo maxPosition: Int) async throws -> [UInt64] {
        guard maxPosition >= 0 else {
            throw FibonacciError.invalidInput("Max position must be non-negative")
        }
        
        var sequence: [UInt64] = []
        for i in 0...maxPosition {
            let value = try await calculate(i)
            sequence.append(value)
        }
        
        return sequence
    }
}

/// Errors that can occur during Fibonacci calculations
public enum FibonacciError: Error, LocalizedError {
    case invalidInput(String)
    case overflow(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .overflow(let message):
            return "Calculation overflow: \(message)"
        }
    }
}

/// Utility functions for Fibonacci calculations
public struct FibonacciUtilities {
    /// Check if a number is a Fibonacci number
    /// - Parameter number: The number to check
    /// - Returns: True if the number is in the Fibonacci sequence
    public static func isFibonacciNumber(_ number: UInt64) -> Bool {
        func isPerfectSquare(_ n: UInt64) -> Bool {
            let sqrt = UInt64(Double(n).squareRoot())
            return sqrt * sqrt == n
        }
        
        // A number is Fibonacci if one of (5*n^2 + 4) or (5*n^2 - 4) is a perfect square
        let test1 = 5 * number * number + 4
        let test2 = 5 * number * number - 4
        
        return isPerfectSquare(test1) || isPerfectSquare(test2)
    }
    
    /// Find the position of a Fibonacci number in the sequence
    /// - Parameter fibNumber: The Fibonacci number to find
    /// - Returns: The position in the sequence, or nil if not found
    public static func findPosition(of fibNumber: UInt64) -> Int? {
        if fibNumber == 0 { return 0 }
        if fibNumber == 1 { return 1 }
        
        var a: UInt64 = 0
        var b: UInt64 = 1
        var position = 1
        
        while b < fibNumber {
            let temp = a + b
            a = b
            b = temp
            position += 1
            
            // Prevent infinite loops for very large numbers
            if position > 100 {
                return nil
            }
        }
        
        return b == fibNumber ? position : nil
    }
}