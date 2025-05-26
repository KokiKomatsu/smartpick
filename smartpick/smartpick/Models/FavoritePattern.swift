import Foundation
import SwiftData

@Model
final class FavoritePattern {
    var numbers: [Int]
    var createdAt: Date
    var memo: String
    var isWinning: Bool
    
    init(numbers: [Int], memo: String = "") {
        self.numbers = numbers.sorted()
        self.createdAt = Date()
        self.memo = memo
        self.isWinning = false
    }
    
    // 表示用の文字列
    var numbersString: String {
        numbers.map { String($0) }.joined(separator: ", ")
    }
    
    // 数字の範囲分析
    var lowRangeCount: Int {
        numbers.filter { $0 <= 21 }.count
    }
    
    var highRangeCount: Int {
        numbers.filter { $0 > 21 }.count
    }
    
    var oddCount: Int {
        numbers.filter { $0 % 2 == 1 }.count
    }
    
    var evenCount: Int {
        numbers.filter { $0 % 2 == 0 }.count
    }
    
    var over40Count: Int {
        numbers.filter { $0 >= 40 }.count
    }
    
    // 連続するペアの数
    var consecutivePairs: Int {
        var count = 0
        for i in 0..<numbers.count - 1 {
            if numbers[i] < 40 && numbers[i+1] < 40 && numbers[i+1] - numbers[i] == 1 {
                count += 1
            }
        }
        return count
    }
}

// MARK: - Extensions
extension FavoritePattern: Equatable {
    static func == (lhs: FavoritePattern, rhs: FavoritePattern) -> Bool {
        return lhs.numbers == rhs.numbers
    }
    
    // 他のパターンとの共通数字数
    func commonNumbers(with other: FavoritePattern) -> Int {
        Set(numbers).intersection(Set(other.numbers)).count
    }
}
