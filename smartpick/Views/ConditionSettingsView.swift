import SwiftUI

struct ConditionSettingsView: View {
    @Binding var conditions: LotoConditions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    SegmentedPicker(
                        title: "40以上の数字の上限",
                        values: Array(0...3),
                        selection: $conditions.over40Count
                    )
                    
                    SegmentedPicker(
                        title: "39以下の連続ペア数",
                        values: Array(0...3),
                        selection: $conditions.consecutivePairCount
                    )
                    
                    SegmentedPicker(
                        title: "1〜21の数字の数",
                        values: Array(0...6),
                        selection: $conditions.lowRangeCount
                    )
                    
                    SegmentedPicker(
                        title: "奇数の数",
                        values: Array(0...6),
                        selection: $conditions.oddCount
                    )
                    
                    SegmentedPicker(
                        title: "パターン間共通数字の上限",
                        values: Array(0...6),
                        selection: $conditions.minUniqueDigits
                    )
                    
                    // 自動計算される値の表示
                    VStack(alignment: .leading, spacing: 16) {
                        Text("自動計算される値")
                            .font(.headline)
                        
                        Group {
                            if conditions.highRangeCount >= 0 {
                                Text("22〜43の数字の数: \(conditions.highRangeCount)")
                            }
                            if conditions.evenCount >= 0 {
                                Text("偶数の数: \(conditions.evenCount)")
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("条件設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        if conditions.validate() {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ConditionSettingsView(conditions: .constant(LotoConditions()))
} 