import SwiftUI

struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct HelpView: View {
    private let sections = [
        HelpSection(
            title: "基本的な使い方",
            content: "1. グリッドから数字を選択します（最低6個必要）\n2. 必要に応じて条件を設定します\n3. 生成したいパターン数を選択します\n4. 「生成」ボタンをタップします"
        ),
        HelpSection(
            title: "条件設定について",
            content: "・40以上の数字の上限: 40〜43の数字をいくつまで使用するか\n・連続ペア数: 39以下の数字で連続する数字のペアをいくつ含めるか\n・1〜21の数字の数: 低い範囲の数字をいくつ含めるか\n・奇数の数: 奇数をいくつ含めるか\n・パターン間共通数字の上限: 生成されたパターン間で共通して良い数字の最大数"
        ),
        HelpSection(
            title: "自動設定について",
            content: "各条件で「自動」を選択すると、その条件を無視してパターンを生成します。これにより、より多くのパターンから選択することができます。"
        ),
        HelpSection(
            title: "エラーについて",
            content: "・選択された数字が少なすぎる場合\n・条件が厳しすぎて組み合わせが見つからない場合\n・条件の組み合わせが矛盾している場合\nなどにエラーが表示されます。条件を緩和するか、数字の選択を見直してください。"
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sections) { section in
                    Section(header: Text(section.title)) {
                        Text(section.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HelpView()
} 