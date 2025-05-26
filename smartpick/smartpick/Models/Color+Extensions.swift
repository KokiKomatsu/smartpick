import SwiftUI

extension Color {
    // アクセントカラー（単色） - Google Gemini カラー基調
    static var accentColor: Color {
        Color(red: 21/255, green: 101/255, blue: 192/255) // #1565C0
    }
    
    // アクセントカラー（グラデーション） - Google Gemini カラー (濃いめ・微調整)
    static var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 21/255, green: 101/255, blue: 192/255), // #1565C0 (Slightly Lighter Dark Blue)
                Color(red: 106/255, green: 27/255, blue: 154/255)  // #6A1B9A (Slightly Lighter Dark Purple)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // 選択背景カラー（グラデーション） - Google Gemini カラー (濃いめ・微調整)
    static var selectionGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 21/255, green: 101/255, blue: 192/255).opacity(0.8), // #1565C0 (Slightly Lighter Dark Blue)
                Color(red: 106/255, green: 27/255, blue: 154/255).opacity(0.8)  // #6A1B9A (Slightly Lighter Dark Purple)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
