import Testing
import Foundation
@testable import ExampleLib

@Suite("Fibonacci Calculator Tests")
struct FibonacciCalculatorTests {
    
    @Test("Basic Fibonacci calculations")
    func testBasicCalculations() async throws {
        let calculator = FibonacciCalculator()
        
        // Test base cases
        #expect(try await calculator.calculate(0) == 0)
        #expect(try await calculator.calculate(1) == 1)
        
        // Test first few numbers
        #expect(try await calculator.calculate(2) == 1)
        #expect(try await calculator.calculate(3) == 2)
        #expect(try await calculator.calculate(4) == 3)
        #expect(try await calculator.calculate(5) == 5)
        #expect(try await calculator.calculate(6) == 8)
        #expect(try await calculator.calculate(7) == 13)
    }
    
    @Test("Invalid input handling")
    func testInvalidInput() async {
        let calculator = FibonacciCalculator()
        
        await #expect(throws: FibonacciError.self) {
            try await calculator.calculate(-1)
        }
        
        await #expect(throws: FibonacciError.self) {
            try await calculator.calculate(-10)
        }
    }
    
    @Test("Caching functionality")
    func testCaching() async throws {
        let calculator = FibonacciCalculator()
        
        // Calculate a number
        let result1 = try await calculator.calculate(10)
        let calculationCount1 = await calculator.getCalculationCount()
        
        // Calculate the same number again
        let result2 = try await calculator.calculate(10)
        let calculationCount2 = await calculator.getCalculationCount()
        
        // Results should be the same
        #expect(result1 == result2)
        
        // But calculation count should be higher due to intermediate calculations
        #expect(calculationCount2 >= calculationCount1)
        
        // Check cache state
        let cache = await calculator.getCacheState()
        #expect(cache[10] == result1)
    }
    
    @Test("Multiple concurrent calculations")
    func testConcurrentCalculations() async throws {
        let calculator = FibonacciCalculator()
        let positions = [5, 7, 10, 12]
        
        let results = try await calculator.calculateMultiple(positions)
        
        #expect(results.count == positions.count)
        #expect(results[5] == 5)
        #expect(results[7] == 13)
        #expect(results[10] == 55)
        #expect(results[12] == 144)
    }
    
    @Test("Sequence generation")
    func testSequenceGeneration() async throws {
        let calculator = FibonacciCalculator()
        
        let sequence = try await calculator.generateSequence(upTo: 7)
        let expected: [UInt64] = [0, 1, 1, 2, 3, 5, 8, 13]
        
        #expect(sequence == expected)
    }
    
    @Test("Cache clearing")
    func testCacheClear() async throws {
        let calculator = FibonacciCalculator()
        
        // Calculate some numbers to populate cache
        _ = try await calculator.calculate(5)
        _ = try await calculator.calculate(8)
        
        let cacheBeforeClear = await calculator.getCacheState()
        #expect(!cacheBeforeClear.isEmpty)
        
        // Clear cache
        await calculator.clearCache()
        
        let cacheAfterClear = await calculator.getCacheState()
        #expect(cacheAfterClear.isEmpty)
    }
    
    @Test("Large number calculation")
    func testLargeNumbers() async throws {
        let calculator = FibonacciCalculator()
        
        // Test larger Fibonacci numbers
        let result20 = try await calculator.calculate(20)
        #expect(result20 == 6765)
        
        let result25 = try await calculator.calculate(25)
        #expect(result25 == 75025)
    }
}

@Suite("Fibonacci Utilities Tests")
struct FibonacciUtilitiesTests {
    
    @Test("Fibonacci number detection")
    func testIsFibonacciNumber() {
        // Test known Fibonacci numbers
        #expect(FibonacciUtilities.isFibonacciNumber(0))
        #expect(FibonacciUtilities.isFibonacciNumber(1))
        #expect(FibonacciUtilities.isFibonacciNumber(1))
        #expect(FibonacciUtilities.isFibonacciNumber(2))
        #expect(FibonacciUtilities.isFibonacciNumber(3))
        #expect(FibonacciUtilities.isFibonacciNumber(5))
        #expect(FibonacciUtilities.isFibonacciNumber(8))
        #expect(FibonacciUtilities.isFibonacciNumber(13))
        #expect(FibonacciUtilities.isFibonacciNumber(21))
        #expect(FibonacciUtilities.isFibonacciNumber(34))
        #expect(FibonacciUtilities.isFibonacciNumber(55))
        
        // Test non-Fibonacci numbers
        #expect(!FibonacciUtilities.isFibonacciNumber(4))
        #expect(!FibonacciUtilities.isFibonacciNumber(6))
        #expect(!FibonacciUtilities.isFibonacciNumber(7))
        #expect(!FibonacciUtilities.isFibonacciNumber(9))
        #expect(!FibonacciUtilities.isFibonacciNumber(10))
        #expect(!FibonacciUtilities.isFibonacciNumber(11))
        #expect(!FibonacciUtilities.isFibonacciNumber(12))
    }
    
    @Test("Position finding")
    func testFindPosition() {
        // Test finding positions of known Fibonacci numbers
        #expect(FibonacciUtilities.findPosition(of: 0) == 0)
        #expect(FibonacciUtilities.findPosition(of: 1) == 1)
        #expect(FibonacciUtilities.findPosition(of: 2) == 3)
        #expect(FibonacciUtilities.findPosition(of: 3) == 4)
        #expect(FibonacciUtilities.findPosition(of: 5) == 5)
        #expect(FibonacciUtilities.findPosition(of: 8) == 6)
        #expect(FibonacciUtilities.findPosition(of: 13) == 7)
        #expect(FibonacciUtilities.findPosition(of: 21) == 8)
        
        // Test non-Fibonacci numbers
        #expect(FibonacciUtilities.findPosition(of: 4) == nil)
        #expect(FibonacciUtilities.findPosition(of: 6) == nil)
        #expect(FibonacciUtilities.findPosition(of: 7) == nil)
        #expect(FibonacciUtilities.findPosition(of: 9) == nil)
    }
}

@Suite("Performance Tests")
struct FibonacciPerformanceTests {
    
    @Test("Concurrent calculation performance", .timeLimit(.minutes(1)))
    func testConcurrentPerformance() async throws {
        let calculator = FibonacciCalculator()
        let positions = Array(0...15) // Calculate first 16 Fibonacci numbers
        
        let startTime = DispatchTime.now()
        let results = try await calculator.calculateMultiple(positions)
        let endTime = DispatchTime.now()
        
        let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        
        #expect(results.count == positions.count)
        #expect(elapsedTime < 60.0) // Should complete within 60 seconds
        
        // Verify some results
        #expect(results[0] == 0)
        #expect(results[10] == 55)
        #expect(results[15] == 610)
    }
}