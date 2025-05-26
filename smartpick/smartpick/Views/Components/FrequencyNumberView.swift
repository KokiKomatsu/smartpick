import SwiftUI

struct FrequencyNumberView: View {
    let number: Int
    let frequencyLevel: Int
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // 基本的なスタイル
    var backgroundColor: Color {
        if isSelected {
            return getBackgroundColorForLevel(frequencyLevel)
        } else {
            return colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)
        }
    }
    
    var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return colorScheme == .dark ? Color.white : Color.black
        }
    }
    
    var borderColor: Color {
        getBackgroundColorForLevel(frequencyLevel)
    }
    
    var borderWidth: CGFloat {
        isSelected ? 0 : (frequencyLevel > 0 ? 2 : 0)
    }
    
    var glowRadius: CGFloat {
        switch frequencyLevel {
        case 3: return 2.5
        case 2: return 1.5
        default: return 0
        }
    }
    
    var glowOpacity: Double {
        switch frequencyLevel {
        case 3: return 0.8
        case 2: return 0.5
        default: return 0
        }
    }
    
    var body: some View {
        Text("\(number)")
            .font(.system(size: 18, weight: frequencyLevel > 1 ? .bold : .medium))
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .shadow(
                        color: borderColor.opacity(glowOpacity),
                        radius: glowRadius,
                        x: 0, y: 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .foregroundColor(foregroundColor)
    }
    
    // 頻度レベルに基づいた色を取得
    private func getBackgroundColorForLevel(_ level: Int) -> Color {
        switch level {
        case 3: return Color.orange  // 3回以上
        case 2: return Color.green   // 2回
        case 1: return Color.blue    // 1回
        default: return Color.gray   // 0回（通常はこのケースはない）
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        FrequencyNumberView(number: 7, frequencyLevel: 3, isSelected: true)
        FrequencyNumberView(number: 12, frequencyLevel: 2, isSelected: true)
        FrequencyNumberView(number: 25, frequencyLevel: 1, isSelected: true)
        FrequencyNumberView(number: 33, frequencyLevel: 0, isSelected: true)
        
        FrequencyNumberView(number: 7, frequencyLevel: 3, isSelected: false)
        FrequencyNumberView(number: 12, frequencyLevel: 2, isSelected: false)
        FrequencyNumberView(number: 25, frequencyLevel: 1, isSelected: false)
        FrequencyNumberView(number: 33, frequencyLevel: 0, isSelected: false)
    }
    .padding()
} 