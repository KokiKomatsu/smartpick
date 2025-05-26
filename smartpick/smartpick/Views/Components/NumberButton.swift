import SwiftUI

import SwiftUI

// ShapeStyleを受け入れるように変更
struct NumberButton<S: ShapeStyle>: View {
    let number: Int
    @Binding var isSelected: Bool
    var selectionStyle: S // ColorからShapeStyleに変更
    var backgroundColor: Color = Color(.systemGray6)
    
    private let buttonSize: CGFloat = 44
    
    // デフォルトのイニシャライザ（Color用）
    init(number: Int, isSelected: Binding<Bool>, selectionColor: Color = Color.blue, backgroundColor: Color = Color(.systemGray6)) where S == Color {
        self.number = number
        self._isSelected = isSelected
        self.selectionStyle = selectionColor
        self.backgroundColor = backgroundColor
    }
    
    // グラデーション用のイニシャライザ
    init(number: Int, isSelected: Binding<Bool>, selectionGradient: S, backgroundColor: Color = Color(.systemGray6)) {
        self.number = number
        self._isSelected = isSelected
        self.selectionStyle = selectionGradient
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text("\(number)")
                .font(.system(size: 18, weight: .medium))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(isSelected ? .white : nil) // 文字色は白のまま
                .background { // backgroundクロージャを使用
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectionStyle) // ShapeStyleを適用
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(backgroundColor)
                    }
                }
                .overlay( // 枠線は主要な色（例：青）を使うか、別途定義が必要
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1) // 一旦青を維持
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Previewの更新 - 共通グラデーション定義を使用
#Preview {
    VStack {
        HStack {
            // Colorを使用するケース
            NumberButton(number: 1, isSelected: .constant(false))
            NumberButton(number: 2, isSelected: .constant(true))
        }
        
        HStack {
            // Gradientを使用するケース
            NumberButton(
                number: 3,
                isSelected: .constant(false),
                selectionGradient: Color.selectionGradient, // 共通定義を使用
                backgroundColor: Color(.systemGray5)
            )
            NumberButton(
                number: 4,
                isSelected: .constant(true),
                selectionGradient: Color.selectionGradient, // 共通定義を使用
                backgroundColor: Color(.systemGray5)
            )
        }
    }
    .padding()
}
