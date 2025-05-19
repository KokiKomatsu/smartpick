import SwiftUI

import SwiftUI

struct ConditionSettingsView: View {
    @Binding var conditions: LotoConditions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme // ダークモード対応のため追加

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    SegmentedPicker(
                        title: "40以上の数字の数",
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
                    .foregroundStyle(Color.accentGradient) // 共通定義を使用
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        if conditions.validate() {
                            dismiss()
                        }
                    }
                    .foregroundStyle(Color.accentGradient) // 共通定義を使用
                }
            }
        }
    }
}

#Preview {
    ConditionSettingsView(conditions: .constant(LotoConditions()))
}
