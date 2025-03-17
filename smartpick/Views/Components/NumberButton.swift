import SwiftUI

struct NumberButton: View {
    let number: Int
    @Binding var isSelected: Bool
    var selectionColor: Color = Color.blue
    var backgroundColor: Color = Color(.systemGray6)
    
    private let buttonSize: CGFloat = 44
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text("\(number)")
                .font(.system(size: 18, weight: .medium))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(isSelected ? .white : nil)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? selectionColor : backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectionColor.opacity(0.3), lineWidth: 1)
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

#Preview {
    VStack {
        HStack {
            NumberButton(number: 1, isSelected: .constant(false))
            NumberButton(number: 2, isSelected: .constant(true))
        }
        
        HStack {
            NumberButton(
                number: 3,
                isSelected: .constant(false),
                selectionColor: .purple,
                backgroundColor: Color(.systemGray5)
            )
            NumberButton(
                number: 4,
                isSelected: .constant(true),
                selectionColor: .purple,
                backgroundColor: Color(.systemGray5)
            )
        }
    }
    .padding()
} 