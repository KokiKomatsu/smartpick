import SwiftUI

struct AlertType: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: AlertStyle
    var autoDisappear: Bool = false
    
    init(title: String, message: String, type: AlertStyle, autoDisappear: Bool? = nil) {
        self.title = title
        self.message = message
        self.type = type
        self.autoDisappear = autoDisappear ?? (type == .success)
    }
}

enum AlertStyle {
    case error
    case warning
    case success
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
}

struct CustomAlert: ViewModifier {
    @Binding var alert: AlertType?
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let alert = alert {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: alert.type.icon)
                            .foregroundColor(alert.type.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title)
                                .font(.headline)
                            Text(alert.message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                self.alert = nil
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                            .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                    )
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        if alert.autoDisappear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation {
                                    if self.alert?.id == alert.id {
                                        self.alert = nil
                                    }
                                }
                            }
                        }
                    }
                }
                .zIndex(1)
            }
        }
    }
}

extension View {
    func customAlert(alert: Binding<AlertType?>) -> some View {
        modifier(CustomAlert(alert: alert))
    }
}

#Preview {
    VStack {
        Text("ライトモード")
            .customAlert(alert: .constant(AlertType(
                title: "エラー",
                message: "選択された数字が不足しています",
                type: .error
            )))
        
        Text("ダークモード")
            .environment(\.colorScheme, .dark)
            .customAlert(alert: .constant(AlertType(
                title: "警告",
                message: "条件を満たすパターンが見つかりません",
                type: .warning
            )))
    }
} 