import Foundation

struct LotoConditions {
    /// 40〜43の数字使用上限（-1は自動設定）
    var over40Count: Int = 0
    
    /// 39以下の数字の連続ペア数（-1は自動設定）
    var consecutivePairCount: Int = 0
    
    /// 1〜21の数字の数（-1は自動設定）
    var lowRangeCount: Int = 0
    
    /// 生成する組み合わせの奇数の数（-1は自動設定）
    var oddCount: Int = 0
    
    /// パターン間で共通して良い数字の最大数（-1は自動設定）
    var minUniqueDigits: Int = 0
    
    /// 22〜43の数字の数（自動計算）
    var highRangeCount: Int {
        return lowRangeCount >= 0 ? 6 - lowRangeCount : -1
    }
    
    /// 偶数の数（自動計算）
    var evenCount: Int {
        return oddCount >= 0 ? 6 - oddCount : -1
    }
    
    static let defaultConditions = LotoConditions()
}

// MARK: - Validation
extension LotoConditions {
    func validate() -> Bool {
        // 基本的な範囲チェック
        guard (over40Count == -1 || (0...3).contains(over40Count)) &&
              (consecutivePairCount == -1 || (0...3).contains(consecutivePairCount)) &&
              (lowRangeCount == -1 || (0...6).contains(lowRangeCount)) &&
              (oddCount == -1 || (0...6).contains(oddCount)) &&
              (minUniqueDigits == -1 || (0...6).contains(minUniqueDigits)) else {
            return false
        }
        
        // 論理的な整合性チェック
        if lowRangeCount >= 0 && highRangeCount < 0 {
            return false
        }
        
        if oddCount >= 0 && evenCount < 0 {
            return false
        }
        
        return true
    }
} 