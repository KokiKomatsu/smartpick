import Foundation

actor PatternGenerator {
    private var selectedNumbers: Set<Int>
    private var conditions: LotoConditions
    private var generatedPatterns: [[Int]] = []
    private var requestedPatternCount: Int
    private var random = CustomRandomGenerator()
    
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
        
        // 選択された数字を配列に変換
        let numbers = Array(selectedNumbers).sorted()
        
        // 最適化されたアプローチ：
        // 1. 少数のパターンが必要な場合は効率的なランダム生成を使用
        // 2. より多くのパターンが必要な場合は早期枝刈りを伴うバックトラッキングを使用
        if requestedPatternCount <= 10 && numbers.count >= 10 {
            // 効率的なランダム生成を使用
            await generateRandomPatterns(from: numbers)
        } else {
            // 早期枝刈りを伴う最適化されたバックトラッキングを使用
            await generateWithOptimizedBacktracking(numbers: numbers, currentCombination: [], startIndex: 0, currentMask: 0)
        }
        
        return generatedPatterns
    }
    
    // ランダム生成アプローチ
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
                        generatedPatterns.append(combination)
                    }
                }
            }
        }
    }
    
    // 最適化されたバックトラッキング
    private func generateWithOptimizedBacktracking(numbers: [Int], currentCombination: [Int], startIndex: Int, currentMask: UInt64) async {
        // 要求されたパターン数に達したら終了
        if generatedPatterns.count >= requestedPatternCount {
            return
        }
        
        // 組み合わせが完成したら検証
        if currentCombination.count == 6 {
            // 複数のawaitを別々のステップに分離
            let isValid = await isValidCombination(currentCombination)
            if isValid {
                let isUnique = await isUniqueCombination(currentCombination)
                if isUnique {
                    generatedPatterns.append(currentCombination)
                }
            }
            return
        }
        
        // 早期枝刈り条件
        if !canLeadToValidCombination(currentCombination: currentCombination, currentMask: currentMask, numbers: numbers, startIndex: startIndex) {
            return
        }
        
        // バックトラッキングによる組み合わせ生成
        for i in startIndex..<numbers.count {
            let number = numbers[i]
            let newMask = currentMask | (UInt64(1) << number)
            var newCombination = currentCombination
            newCombination.append(number)
            
            await generateWithOptimizedBacktracking(
                numbers: numbers,
                currentCombination: newCombination,
                startIndex: i + 1,
                currentMask: newMask
            )
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
        if conditions.minUniqueDigits >= 0 {
            let combinationSet = Set(combination)
            for pattern in generatedPatterns {
                let patternSet = Set(pattern)
                let intersection = combinationSet.intersection(patternSet)
                if intersection.count > conditions.minUniqueDigits {
                    return false
                }
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
        
        // 連続ペアのチェック
        if conditions.consecutivePairCount >= 0 {
            let consecutivePairs = countConsecutivePairs(in: combination)
            if consecutivePairs != conditions.consecutivePairCount {
                return false
            }
        }
        
        return true
    }
    
    private func countConsecutivePairs(in numbers: [Int]) -> Int {
        let sortedNumbers = numbers.sorted()
        var pairCount = 0
        
        for i in 0..<sortedNumbers.count-1 {
            if sortedNumbers[i] < 40 && sortedNumbers[i+1] < 40 && sortedNumbers[i+1] - sortedNumbers[i] == 1 {
                pairCount += 1
            }
        }
        
        return pairCount
    }
}

// カスタムランダム数生成器
private struct CustomRandomGenerator: RandomNumberGenerator {
    private var source = SystemRandomNumberGenerator()
    
    init() {}
    
    mutating func next() -> UInt64 {
        source.next()
    }
} 