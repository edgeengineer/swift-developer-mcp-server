import Foundation
import ExampleLib

@main
struct ExampleApp {
    static func main() async {
        print("🧮 Fibonacci Calculator Demo")
        print("============================")
        
        let calculator = FibonacciCalculator()
        
        do {
            // Demo 1: Basic calculations
            print("\n📊 Basic Fibonacci calculations:")
            for i in 0...10 {
                let result = try await calculator.calculate(i)
                print("F(\(i)) = \(result)")
            }
            
            // Demo 2: Cache demonstration
            print("\n💾 Cache demonstration:")
            let cacheState = await calculator.getCacheState()
            print("Current cache contains \(cacheState.count) entries")
            let calculationCount = await calculator.getCalculationCount()
            print("Total calculations performed: \(calculationCount)")
            
            // Demo 3: Concurrent calculations
            print("\n⚡ Concurrent calculations:")
            let positions = [15, 20, 25, 30]
            let startTime = DispatchTime.now()
            let results = try await calculator.calculateMultiple(positions)
            let endTime = DispatchTime.now()
            
            let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            
            for position in positions.sorted() {
                if let result = results[position] {
                    print("F(\(position)) = \(result)")
                }
            }
            print("Concurrent calculation took \(String(format: "%.3f", elapsedTime)) seconds")
            
            // Demo 4: Sequence generation
            print("\n🔢 Sequence generation:")
            let sequence = try await calculator.generateSequence(upTo: 12)
            print("First 13 Fibonacci numbers: \(sequence)")
            
            // Demo 5: Utility functions
            print("\n🔍 Utility functions:")
            let testNumbers: [UInt64] = [8, 9, 13, 14, 21, 22]
            for number in testNumbers {
                let isFib = FibonacciUtilities.isFibonacciNumber(number)
                let position = FibonacciUtilities.findPosition(of: number)
                print("Number \(number): is Fibonacci = \(isFib), position = \(position?.description ?? "N/A")")
            }
            
            // Demo 6: Error handling
            print("\n❌ Error handling demonstration:")
            do {
                _ = try await calculator.calculate(-5)
            } catch let error as FibonacciError {
                print("Caught expected error: \(error.localizedDescription)")
            }
            
            // Demo 7: Performance test with breakpoint opportunity
            print("\n🏃‍♂️ Performance test (good for debugging):")
            await performanceTest(calculator: calculator)
            
            print("\n✅ Demo completed successfully!")
            
        } catch {
            print("❌ Error occurred: \(error)")
        }
    }
    
    static func performanceTest(calculator: FibonacciCalculator) async {
        print("Starting performance test...")
        
        // Clear cache for fair test
        await calculator.clearCache()
        
        let testPositions = [10, 15, 20, 25, 30]
        var totalTime: Double = 0
        
        for position in testPositions {
            let startTime = DispatchTime.now()
            
            do {
                let result = try await calculator.calculate(position)
                let endTime = DispatchTime.now()
                let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
                totalTime += elapsedTime
                
                print("F(\(position)) = \(result) (calculated in \(String(format: "%.3f", elapsedTime))s)")
                
                // Add a small delay to make debugging easier
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
            } catch {
                print("Error calculating F(\(position)): \(error)")
            }
        }
        
        print("Total performance test time: \(String(format: "%.3f", totalTime)) seconds")
        
        let finalCalculationCount = await calculator.getCalculationCount()
        print("Final calculation count: \(finalCalculationCount)")
    }
}