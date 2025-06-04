# Debug Variables in FibonacciCalculatorTests.swift

## 1. Basic Test Variables (testBasicCalculations - Line 10)

Set breakpoint at line 13 and inspect:

```bash
# Inspect the calculator actor
debug_inspect_variable session_id calculator

# Expected output: Shows FibonacciCalculator actor instance
```

## 2. Caching Test Variables (testCaching - Lines 40-48)

Set breakpoint at line 43 and inspect:

```bash
# Inspect calculator instance
debug_inspect_variable session_id calculator

# Inspect first result
debug_inspect_variable session_id result1

# Inspect calculation count
debug_inspect_variable session_id calculationCount1
```

Set breakpoint at line 47 and inspect:

```bash
# Inspect second result (should be same as first)
debug_inspect_variable session_id result2

# Inspect updated calculation count
debug_inspect_variable session_id calculationCount2

# Compare results
debug_inspect_variable session_id --expression "result1 == result2"
```

## 3. Concurrent Calculation Variables (testConcurrentCalculations - Lines 68-75)

Set breakpoint at line 70 and inspect:

```bash
# Inspect positions array
debug_inspect_variable session_id positions

# Inspect results dictionary
debug_inspect_variable session_id results

# Check specific result
debug_inspect_variable session_id --expression "results[5]"
```

## 4. Performance Test Variables (testConcurrentPerformance - Lines 168-185)

Set breakpoint at line 175 and inspect:

```bash
# Inspect calculator state
debug_inspect_variable session_id calculator

# Inspect positions array
debug_inspect_variable session_id positions

# Inspect start time
debug_inspect_variable session_id startTime

# Inspect end time
debug_inspect_variable session_id endTime

# Calculate elapsed time
debug_inspect_variable session_id elapsedTime

# Inspect results dictionary
debug_inspect_variable session_id results
```

## 5. Cache State Inspection (testCacheClear - Lines 96-108)

Set breakpoint at line 102 and inspect:

```bash
# Inspect cache before clear
debug_inspect_variable session_id cacheBeforeClear

# Check if cache is empty
debug_inspect_variable session_id --expression "cacheBeforeClear.isEmpty"
```

Set breakpoint at line 107 and inspect:

```bash
# Inspect cache after clear
debug_inspect_variable session_id cacheAfterClear

# Verify cache is empty
debug_inspect_variable session_id --expression "cacheAfterClear.isEmpty"
```

## 6. Actor State Inspection

At any breakpoint where calculator is available:

```bash
# Get cache state from actor
debug_inspect_variable session_id --expression "await calculator.getCacheState()"

# Get calculation count from actor
debug_inspect_variable session_id --expression "await calculator.getCalculationCount()"

# Check if actor has specific cached value
debug_inspect_variable session_id --expression "await calculator.getCacheState()[10]"
```

## 7. Error Handling Variables (testInvalidInput - Lines 26-35)

Set breakpoint at line 29 and inspect:

```bash
# Inspect calculator before error
debug_inspect_variable session_id calculator

# The error will be caught by the expect statement
```

## 8. Sequence Generation Variables (testSequenceGeneration - Lines 114-121)

Set breakpoint at line 118 and inspect:

```bash
# Inspect generated sequence
debug_inspect_variable session_id sequence

# Inspect expected sequence
debug_inspect_variable session_id expected

# Compare sequences
debug_inspect_variable session_id --expression "sequence == expected"
```

## Complete Debug Workflow Example

1. Start debug session:
```bash
debug_start ExampleLibTests /path/to/ExampleLib
```

2. Set breakpoint in caching test:
```bash
debug_set_breakpoint /path/to/ExampleLib/Tests/ExampleLibTests/FibonacciCalculatorTests.swift 43 session_id
```

3. Start test execution:
```bash
debug_continue session_id
```

4. When breakpoint hits, inspect variables:
```bash
debug_inspect_variable session_id calculator
debug_inspect_variable session_id result1
debug_inspect_variable session_id --expression "await calculator.getCalculationCount()"
```

5. Step through and continue inspection:
```bash
debug_step session_id over
debug_inspect_variable session_id result2
debug_inspect_variable session_id --expression "result1 == result2"
```

6. Clean up:
```bash
debug_terminate session_id
```