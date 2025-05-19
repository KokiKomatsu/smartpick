import SwiftUI

struct SegmentedPicker: View {
    let title: String
    let values: [Int]
    @Binding var selection: Int
    @Environment(\.colorScheme) private var colorScheme // ダークモード対応のため追加

    // 非選択時の背景色
    private var defaultBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    // 非選択時のテキスト色
    private var defaultForegroundColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: {
                        selection = -1
                    }) {
                        Text("自動")
                            .frame(minWidth: 60)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background { // backgroundクロージャを使用
                                if selection == -1 {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentGradient) // 共通定義を使用
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(defaultBackgroundColor)
                                }
                            }
                            .foregroundColor(selection == -1 ? .white : defaultForegroundColor)
                    }
                    
                    ForEach(values, id: \.self) { value in
                        Button(action: {
                            selection = value
                        }) {
                            Text("\(value)")
                                .frame(minWidth: 60)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background { // backgroundクロージャを使用
                                    if selection == value {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentGradient) // 共通定義を使用
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(defaultBackgroundColor)
                                    }
                                }
                                .foregroundColor(selection == value ? .white : defaultForegroundColor)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

#Preview {
    SegmentedPicker(
        title: "40以上の数字",
        values: Array(0...3),
        selection: .constant(1)
    )
    .padding()
}
