import Foundation
import SwiftData
import SwiftUI

@Observable
class FavoritePatternService {
    private var modelContext: ModelContext
    private(set) var favoritePatterns: [FavoritePattern] = []
    private(set) var duplicateAnalysis: DuplicateAnalysis = DuplicateAnalysis()
    
    static let maxFavorites = 5
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFavorites()
    }
    
    // MARK: - Basic Operations
    
    func loadFavorites() {
        do {
            let descriptor = FetchDescriptor<FavoritePattern>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            favoritePatterns = try modelContext.fetch(descriptor)
            updateDuplicateAnalysis()
        } catch {
            print("お気に入り読み込みエラー: \(error)")
            favoritePatterns = []
        }
    }
    
    func addFavorite(_ numbers: [Int], memo: String = "") -> Bool {
        guard canAddFavorite(numbers) else { return false }
        
        // 最大数に達している場合は最古のものを削除
        if favoritePatterns.count >= Self.maxFavorites {
            if let oldest = favoritePatterns.last {
                removeFavorite(oldest)
            }
        }
        
        let newPattern = FavoritePattern(numbers: numbers, memo: memo)
        modelContext.insert(newPattern)
        
        do {
            try modelContext.save()
            loadFavorites()
            return true
        } catch {
            print("お気に入り保存エラー: \(error)")
            return false
        }
    }
    
    func removeFavorite(_ pattern: FavoritePattern) {
        modelContext.delete(pattern)
        
        do {
            try modelContext.save()
            loadFavorites()
        } catch {
            print("お気に入り削除エラー: \(error)")
        }
    }
    
    func updateMemo(for pattern: FavoritePattern, memo: String) {
        pattern.memo = memo
        
        do {
            try modelContext.save()
            loadFavorites()
        } catch {
            print("メモ更新エラー: \(error)")
        }
    }
    
    func markAsWinning(_ pattern: FavoritePattern, isWinning: Bool) {
        pattern.isWinning = isWinning
        
        do {
            try modelContext.save()
            loadFavorites()
        } catch {
            print("当選フラグ更新エラー: \(error)")
        }
    }
    
    // MARK: - Validation
    
    func canAddFavorite(_ numbers: [Int]) -> Bool {
        let sortedNumbers = numbers.sorted()
        return !favoritePatterns.contains { $0.numbers == sortedNumbers }
    }
    
    func isFavorite(_ numbers: [Int]) -> Bool {
        let sortedNumbers = numbers.sorted()
        return favoritePatterns.contains { $0.numbers == sortedNumbers }
    }
    
    // MARK: - Duplicate Analysis
    
    private func updateDuplicateAnalysis() {
        duplicateAnalysis = DuplicateAnalysis(patterns: favoritePatterns)
    }
    
    func getNumberFrequency(_ number: Int) -> Int {
        duplicateAnalysis.numberFrequency[number] ?? 0
    }
    
    func getMaxFrequency() -> Int {
        duplicateAnalysis.numberFrequency.values.max() ?? 0
    }
    
    func getMostFrequentNumbers() -> [Int] {
        let maxFreq = getMaxFrequency()
        return duplicateAnalysis.numberFrequency.compactMap { key, value in
            value == maxFreq ? key : nil
        }.sorted()
    }
    
    func getLeastFrequentNumbers() -> [Int] {
        let minFreq = duplicateAnalysis.numberFrequency.values.min() ?? 0
        return duplicateAnalysis.numberFrequency.compactMap { key, value in
            value == minFreq ? key : nil
        }.sorted()
    }
}

// MARK: - Duplicate Analysis Model

struct DuplicateAnalysis {
    let numberFrequency: [Int: Int]
    let patternSimilarity: [PatternSimilarity]
    let statistics: AnalysisStatistics
    
    init(patterns: [FavoritePattern] = []) {
        var frequency: [Int: Int] = [:]
        var similarities: [PatternSimilarity] = []
        
        // 各数字の頻度を計算
        for pattern in patterns {
            for number in pattern.numbers {
                frequency[number, default: 0] += 1
            }
        }
        
        // パターン間の類似度を計算
        for i in 0..<patterns.count {
            for j in (i+1)..<patterns.count {
                let pattern1 = patterns[i]
                let pattern2 = patterns[j]
                let commonCount = pattern1.commonNumbers(with: pattern2)
                
                similarities.append(PatternSimilarity(
                    pattern1: pattern1,
                    pattern2: pattern2,
                    commonNumbers: commonCount,
                    similarity: Double(commonCount) / 6.0
                ))
            }
        }
        
        self.numberFrequency = frequency
        self.patternSimilarity = similarities.sorted { $0.similarity > $1.similarity }
        self.statistics = AnalysisStatistics(
            totalPatterns: patterns.count,
            uniqueNumbers: frequency.keys.count,
            averageFrequency: frequency.values.isEmpty ? 0 : Double(frequency.values.reduce(0, +)) / Double(frequency.keys.count),
            maxSimilarity: similarities.map(\.similarity).max() ?? 0.0
        )
    }
}

struct PatternSimilarity {
    let pattern1: FavoritePattern
    let pattern2: FavoritePattern
    let commonNumbers: Int
    let similarity: Double
}

struct AnalysisStatistics {
    let totalPatterns: Int
    let uniqueNumbers: Int
    let averageFrequency: Double
    let maxSimilarity: Double
    
    var diversityScore: Double {
        guard totalPatterns > 0 else { return 0 }
        let maxPossibleUnique = totalPatterns * 6
        return Double(uniqueNumbers) / Double(maxPossibleUnique)
    }
}