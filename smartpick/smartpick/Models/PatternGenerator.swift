import Foundation

actor PatternGenerator {
    private var selectedNumbers: Set<Int>
    private var conditions: LotoConditions
    private var generatedPatterns: [[Int]] = []
    private var requestedPatternCount: Int
    private var random = CustomRandomGenerator()
    
    // 並列化用: 生成済みパターンのスレッドセーフ管理
    private let patternStore = PatternStore()
    // CPUコア数に応じてタスク数を最適化
    private let cpuCount = max(ProcessInfo.processInfo.activeProcessorCount, 2)
    
    // ビット操作のための定数
    private let lowRangeMask: UInt64 = (1 << 21) - 1  // 1-21の数字用ビットマスク
    private let over40Mask: UInt64 = (UInt64(1) << 40 | UInt64(1) << 41 | UInt64(1) << 42 | UInt64(1) << 43)  // 40-43用ビットマスク
    
    init(selectedNumbers: Set<Int>, conditions: LotoConditions, requestedPatternCount: Int) {
        self.selectedNumbers = selectedNumbers
        self.conditions = conditions
        self.requestedPatternCount = requestedPatternCount
    }
    
    func generate() async -> [[Int]] {
        generatedPatterns = []
        await patternStore.clear()
        await patternStore.setMaxCount(requestedPatternCount)
        let numbers = Array(selectedNumbers).sorted()
        
        if requestedPatternCount <= 10 && numbers.count >= 10 {
            // タスク数をCPUコア数に最適化
            let tasksCount = cpuCount
            let patternsPerTask = max(requestedPatternCount / tasksCount + 1, 3)
            await withTaskGroup(of: [[Int]].self) { group in
                for _ in 0..<tasksCount {
                    group.addTask {
                        await self.generateRandomPatternsTask(from: numbers, count: patternsPerTask)
                    }
                }
                for await patterns in group {
                    for pattern in patterns {
                        let sortedPattern = pattern.sorted()
                        await self.patternStore.appendIfUnique(sortedPattern, minUniqueDigits: self.conditions.minUniqueDigits)
                        if await self.patternStore.count >= self.requestedPatternCount {
                            return
                        }
                    }
                }
            }
            generatedPatterns = await patternStore.patterns
        } else {
            // バックトラッキングの並列化を2段階目まで拡張
            await generateWithOptimizedBacktrackingParallel(numbers: numbers)
            generatedPatterns = await patternStore.patterns
        }
        return generatedPatterns
    }
    
    // 単一のタスクでランダムパターンを生成
    private func generateRandomPatternsTask(from numbers: [Int], count: Int) async -> [[Int]] {
        var localPatterns: [[Int]] = []
        let maxAttempts = max(count * 20, 200)
        var attempts = 0
        
        // 特定の数字グループからのインデックス範囲を計算
        let lowRangeIndices = numbers.indices.filter { numbers[$0] <= 21 }
        let highRangeIndices = numbers.indices.filter { numbers[$0] > 21 && numbers[$0] < 40 }
        let over40Indices = numbers.indices.filter { numbers[$0] >= 40 }
        
        // ローカルのランダムジェネレーター
        var localRandom = CustomRandomGenerator()
        
        while localPatterns.count < count && attempts < maxAttempts {
            attempts += 1
            let currentCount = await patternStore.count
            let maxCount = await patternStore.maxCount
            if currentCount >= maxCount { break }
            
            // 条件に基づいて選択する数字を決定
            var selectedIndices = Set<Int>()
            var combination: [Int] = []
            
            // 1. 低範囲の数字 (1-21)
            let targetLowCount = conditions.lowRangeCount >= 0 ? conditions.lowRangeCount : Int.random(in: 0...min(6, lowRangeIndices.count), using: &localRandom)
            if !lowRangeIndices.isEmpty && targetLowCount > 0 {
                for _ in 0..<targetLowCount {
                    if let randomIndex = lowRangeIndices.randomElement(using: &localRandom) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 2. 40以上の数字
            let maxOver40Count = conditions.over40Count >= 0 ? 
                min(conditions.over40Count, 6 - combination.count) : 
                min(min(2, over40Indices.count), 6 - combination.count)

            // 上限として機能するよう0〜maxOver40Countの範囲からランダムに選択
            let targetOver40Count = conditions.over40Count >= 0 ?
                Int.random(in: 0...maxOver40Count, using: &localRandom) : // 0から上限値までのランダムに変更
                Int.random(in: 0...min(min(2, over40Indices.count), 6 - combination.count), using: &localRandom)

            if !over40Indices.isEmpty && targetOver40Count > 0 {
                for _ in 0..<targetOver40Count {
                    if let randomIndex = over40Indices.randomElement(using: &localRandom) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 3. 残りの数字を22-39から選択
            let remainingCount = 6 - combination.count
            if remainingCount > 0 && !highRangeIndices.isEmpty {
                for _ in 0..<remainingCount {
                    if let randomIndex = highRangeIndices.randomElement(using: &localRandom) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 4. まだ6個に満たない場合は、残りの利用可能な数字から選択
            while combination.count < 6 {
                let remainingIndices = numbers.indices.filter { !selectedIndices.contains($0) }
                if remainingIndices.isEmpty {
                    break
                }
                if let randomIndex = remainingIndices.randomElement(using: &localRandom) {
                    selectedIndices.insert(randomIndex)
                    combination.append(numbers[randomIndex])
                }
            }
            
            // 組み合わせが6個で構成されているか確認
            if combination.count == 6 {
                let isValid = isValidCombinationLocal(combination)
                if isValid {
                    // 生成されたパターンが他のものと十分に異なるか確認
                    let isUnique = isUniqueCombinationLocal(combination, patterns: localPatterns)
                    if isUnique {
                        localPatterns.append(combination)
                    }
                }
            }
        }
        
        return localPatterns
    }
    
    // ランダム生成アプローチ（メインスレッド用）
    private func generateRandomPatterns(from numbers: [Int]) async {
        // 最大試行回数
        let maxAttempts = max(requestedPatternCount * 20, 1000)
        var attempts = 0
        
        // 特定の数字グループからのインデックス範囲を計算
        let lowRangeIndices = numbers.indices.filter { numbers[$0] <= 21 }
        let highRangeIndices = numbers.indices.filter { numbers[$0] > 21 && numbers[$0] < 40 }
        let over40Indices = numbers.indices.filter { numbers[$0] >= 40 }
        
        while generatedPatterns.count < requestedPatternCount && attempts < maxAttempts {
            attempts += 1
            
            // 条件に基づいて選択する数字を決定
            var selectedIndices = Set<Int>()
            var combination: [Int] = []
            
            // 1. 低範囲の数字 (1-21)
            let targetLowCount = conditions.lowRangeCount >= 0 ? conditions.lowRangeCount : Int.random(in: 0...min(6, lowRangeIndices.count))
            if !lowRangeIndices.isEmpty && targetLowCount > 0 {
                for _ in 0..<targetLowCount {
                    if let randomIndex = lowRangeIndices.randomElement(using: &random) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 2. 40以上の数字
            let maxOver40Count = conditions.over40Count >= 0 ? 
                min(conditions.over40Count, 6 - combination.count) : 
                min(min(2, over40Indices.count), 6 - combination.count)
            
            // 上限として機能するよう0〜maxOver40Countの範囲からランダムに選択
            let targetOver40Count = conditions.over40Count >= 0 ?
                Int.random(in: 0...maxOver40Count) :
                Int.random(in: 0...min(min(2, over40Indices.count), 6 - combination.count))
            
            if !over40Indices.isEmpty && targetOver40Count > 0 {
                for _ in 0..<targetOver40Count {
                    if let randomIndex = over40Indices.randomElement(using: &random) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 3. 残りの数字を22-39から選択
            let remainingCount = 6 - combination.count
            if remainingCount > 0 && !highRangeIndices.isEmpty {
                for _ in 0..<remainingCount {
                    if let randomIndex = highRangeIndices.randomElement(using: &random) {
                        if !selectedIndices.contains(randomIndex) {
                            selectedIndices.insert(randomIndex)
                            combination.append(numbers[randomIndex])
                        }
                    }
                }
            }
            
            // 4. まだ6個に満たない場合は、残りの利用可能な数字から選択
            while combination.count < 6 {
                let remainingIndices = numbers.indices.filter { !selectedIndices.contains($0) }
                if remainingIndices.isEmpty {
                    break
                }
                if let randomIndex = remainingIndices.randomElement(using: &random) {
                    selectedIndices.insert(randomIndex)
                    combination.append(numbers[randomIndex])
                }
            }
            
            // 組み合わせが6個で構成されているか確認
            if combination.count == 6 {
                let isValid = await isValidCombination(combination)
                if isValid {
                    // パターン間の共通数字数チェック
                    let isUnique = await isUniqueCombination(combination)
                    if isUnique {
                        generatedPatterns.append(combination.sorted())
                    }
                }
            }
        }
    }
    
    // 最適化されたバックトラッキング
    private func generateWithOptimizedBacktracking(numbers: [Int], currentCombination: [Int], startIndex: Int, currentMask: UInt64) async {
        let currentCount = await patternStore.count
        let maxCount = await patternStore.maxCount
        if currentCount >= maxCount {
            return
        }
        
        // 組み合わせが完成したら検証
        if currentCombination.count == 6 {
            // 複数のawaitを別々のステップに分離
            let isValid = await isValidCombination(currentCombination)
            if isValid {
                let isUnique = await isUniqueCombination(currentCombination)
                if isUnique {
                    await patternStore.appendIfUnique(currentCombination, minUniqueDigits: conditions.minUniqueDigits)
                    let newCount = await patternStore.count
                    let maxCount = await patternStore.maxCount
                    if newCount >= maxCount {
                        return
                    }
                }
            }
            return
        }
        
        // 早期枝刈り条件
        if !canLeadToValidCombination(currentCombination: currentCombination, currentMask: currentMask, numbers: numbers, startIndex: startIndex) {
            return
        }
        
        // 並列処理が可能な条件: 最初の数字を選ぶときのみ並列化
        if currentCombination.isEmpty && numbers.count > 20 {
            // 最初の枝分かれのみ並列処理
            await withTaskGroup(of: Void.self) { group in
                // 選択する数字の範囲を分割
                let chunkSize = max(1, numbers.count / 8)
                
                for chunkStart in stride(from: startIndex, to: numbers.count, by: chunkSize) {
                    let chunkEnd = min(chunkStart + chunkSize, numbers.count)
                    
                    group.addTask {
                        for i in chunkStart..<chunkEnd {
                            let number = numbers[i]
                            let newMask = currentMask | (UInt64(1) << number)
                            var newCombination = currentCombination
                            newCombination.append(number)
                            
                            await self.generateWithOptimizedBacktracking(
                                numbers: numbers,
                                currentCombination: newCombination,
                                startIndex: i + 1,
                                currentMask: newMask
                            )
                        }
                    }
                }
            }
        } else {
            // 通常のバックトラッキング
            for i in startIndex..<numbers.count {
                let number = numbers[i]
                let newMask = currentMask | (UInt64(1) << number)
                let comb1 = [number]
                
                await generateWithOptimizedBacktracking(
                    numbers: numbers,
                    currentCombination: comb1,
                    startIndex: i + 1,
                    currentMask: newMask
                )
            }
        }
    }
    
    // 早期枝刈りのための条件チェック
    private func canLeadToValidCombination(currentCombination: [Int], currentMask: UInt64, numbers: [Int], startIndex: Int) -> Bool {
        let currentCount = currentCombination.count
        let remainingCount = 6 - currentCount
        
        // 選択可能な残りの数字が足りなければ枝刈り
        if startIndex + remainingCount > numbers.count {
            return false
        }
        
        // 低範囲の数字 (1-21) の条件チェック
        if conditions.lowRangeCount >= 0 {
            let lowRangeBits = currentMask & lowRangeMask
            let currentLowCount = lowRangeBits.nonzeroBitCount
            
            // 現在の1-21の数字の数
            let maxPotentialLowCount = currentLowCount + min(remainingCount, numbers[startIndex...].filter { $0 <= 21 }.count)
            let minPotentialLowCount = currentLowCount
            
            if maxPotentialLowCount < conditions.lowRangeCount || minPotentialLowCount > conditions.lowRangeCount {
                return false
            }
        }
        
        // 40以上の数字の条件チェック
        if conditions.over40Count >= 0 {
            let over40Bits = currentMask & over40Mask
            let currentOver40Count = over40Bits.nonzeroBitCount
            
            // 現在の40以上の数字の数が既に上限を超えていれば枝刈り
            if currentOver40Count > conditions.over40Count {
                return false
            }
        }
        
        // 奇数の条件チェック
        if conditions.oddCount >= 0 {
            let oddCount = currentCombination.filter { $0 % 2 == 1 }.count
            let maxPotentialOddCount = oddCount + min(remainingCount, numbers[startIndex...].filter { $0 % 2 == 1 }.count)
            let minPotentialOddCount = oddCount
            
            if maxPotentialOddCount < conditions.oddCount || minPotentialOddCount > conditions.oddCount {
                return false
            }
        }
        
        return true
    }
    
    // 生成されたパターンとの比較
    private func isUniqueCombination(_ combination: [Int]) async -> Bool {
        // 完全一致（順不同）重複チェック
        let normalizedCombination = combination.sorted()
        for pattern in generatedPatterns {
            if pattern.sorted() == normalizedCombination {
                return false
            }
        }
        // パターン間共通数字数チェック
        if conditions.minUniqueDigits >= 0 {
            let combinationSet = Set(combination)
            for pattern in generatedPatterns {
                let patternSet = Set(pattern)
                let commonCount = combinationSet.intersection(patternSet).count
                // minUniqueDigitsはユニークな数字の最小数なので、共通数字の最大数は6 - minUniqueDigits
                if commonCount > (6 - conditions.minUniqueDigits) {
                    return false
                }
            }
        }
        return true
    }
    
    // 並列処理用のローカル版：パターン共通数字チェック
    private func isUniqueCombinationLocal(_ combination: [Int], patterns: [[Int]]) -> Bool {
        // 完全一致（順不同）重複チェック
        let normalizedCombination = combination.sorted()
        for pattern in patterns {
            if pattern.sorted() == normalizedCombination {
                return false
            }
        }
        // パターン間共通数字数チェック
        if conditions.minUniqueDigits >= 0 {
            let combinationSet = Set(combination)
            for pattern in patterns {
                let patternSet = Set(pattern)
                let intersection = combinationSet.intersection(patternSet)
                if intersection.count > (6 - conditions.minUniqueDigits) {
                    return false
                }
            }
        }
        return true
    }
    
    // 並列処理用のローカル版：パターン条件チェック
    private func isValidCombinationLocal(_ combination: [Int]) -> Bool {
        // 基本的な条件チェック
        let over40Numbers = combination.filter { $0 >= 40 }
        // 40以上の数字は上限値以下であればOK（完全に一致する必要はない）
        if conditions.over40Count >= 0 && over40Numbers.count > conditions.over40Count {
            return false
        }
        
        let lowRangeNumbers = combination.filter { $0 <= 21 }
        if conditions.lowRangeCount >= 0 && lowRangeNumbers.count != conditions.lowRangeCount {
            return false
        }
        
        let oddNumbers = combination.filter { $0 % 2 == 1 }
        if conditions.oddCount >= 0 && oddNumbers.count != conditions.oddCount {
            return false
        }
        
        // 連続するペアチェック
        if conditions.consecutivePairCount >= 0 {
            var pairCount = 0
            let sortedNumbers = combination.sorted()
            
            for i in 0..<sortedNumbers.count - 1 {
                if sortedNumbers[i] < 40 && sortedNumbers[i+1] < 40 && sortedNumbers[i+1] - sortedNumbers[i] == 1 {
                    pairCount += 1
                }
            }
            
            if pairCount != conditions.consecutivePairCount {
                return false
            }
        }
        
        return true
    }
    
    // 組み合わせが条件を満たすかチェック
    private func isValidCombination(_ combination: [Int]) async -> Bool {
        // 基本的な条件チェック
        let over40Numbers = combination.filter { $0 >= 40 }
        // 40以上の数字は上限値以下であればOK（完全に一致する必要はない）
        if conditions.over40Count >= 0 && over40Numbers.count > conditions.over40Count {
            return false
        }
        
        let lowRangeNumbers = combination.filter { $0 <= 21 }
        if conditions.lowRangeCount >= 0 && lowRangeNumbers.count != conditions.lowRangeCount {
            return false
        }
        
        let oddNumbers = combination.filter { $0 % 2 == 1 }
        if conditions.oddCount >= 0 && oddNumbers.count != conditions.oddCount {
            return false
        }
        
        // 連続するペアチェック
        if conditions.consecutivePairCount >= 0 {
            var pairCount = 0
            let sortedNumbers = combination.sorted()
            
            for i in 0..<sortedNumbers.count - 1 {
                if sortedNumbers[i] < 40 && sortedNumbers[i+1] < 40 && sortedNumbers[i+1] - sortedNumbers[i] == 1 {
                    pairCount += 1
                }
            }
            
            if pairCount != conditions.consecutivePairCount {
                return false
            }
        }
        
        return true
    }
    
    // バックトラッキングの並列化を2段階目まで拡張
    private func generateWithOptimizedBacktrackingParallel(numbers: [Int]) async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<numbers.count {
                let number1 = numbers[i]
                let mask1 = UInt64(1) << number1
                let comb1 = [number1]
                // 2段階目まで並列化
                for j in (i+1)..<numbers.count {
                    let number2 = numbers[j]
                    let mask2 = mask1 | (UInt64(1) << number2)
                    var comb2 = comb1
                    comb2.append(number2)
                    group.addTask {
                        await self.generateWithOptimizedBacktracking(
                            numbers: numbers,
                            currentCombination: comb2,
                            startIndex: j + 1,
                            currentMask: mask2
                        )
                    }
                }
            }
        }
    }
}

// カスタムランダム生成器
struct CustomRandomGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)) {
        self.seed = seed &* 6364136223846793005 &+ 1
    }
    
    mutating func next() -> UInt64 {
        seed = seed &* 6364136223846793005 &+ 1
        return seed
    }
}

// 生成済みパターンのスレッドセーフ管理用actor
actor PatternStore {
    private(set) var patterns: [[Int]] = []
    private(set) var maxCount: Int = Int.max
    func setMaxCount(_ count: Int) { self.maxCount = count }
    func appendIfUnique(_ pattern: [Int], minUniqueDigits: Int) {
        if patterns.count >= maxCount { return }
        // 完全一致重複チェック
        if patterns.contains(where: { $0 == pattern }) { return }
        // パターン間共通数字数チェック
        if minUniqueDigits >= 0 {
            let patternSet = Set(pattern)
            for p in patterns {
                let pSet = Set(p)
                let commonCount = patternSet.intersection(pSet).count
                if commonCount > (6 - minUniqueDigits) { return }
            }
        }
        patterns.append(pattern)
    }
    func clear() { patterns.removeAll() }
    var count: Int { patterns.count }
}
