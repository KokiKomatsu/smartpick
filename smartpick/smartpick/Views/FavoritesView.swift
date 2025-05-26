import SwiftUI
import SwiftData

struct FavoritesView: View {
    var favoriteService: FavoritePatternService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab = 0
    @State private var showingAnalysis = false
    @State private var editingPattern: FavoritePattern?
    @State private var editingMemo = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // カスタムタブセレクター
                FavoriteTabSelector(selectedTab: $selectedTab)
                    .padding()
                
                TabView(selection: $selectedTab) {
                    // お気に入りパターン一覧
                    FavoritePatternsList(
                        favoriteService: favoriteService,
                        editingPattern: $editingPattern,
                        editingMemo: $editingMemo
                    )
                    .tag(0)
                    
                    // 分析ビュー
                    FavoriteAnalysisView(favoriteService: favoriteService)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("お気に入り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accentGradient)
                }
                
                if selectedTab == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAnalysis = true
                        }) {
                            Image(systemName: "chart.bar.xaxis")
                                .foregroundStyle(Color.accentGradient)
                        }
                    }
                }
            }
            .sheet(item: $editingPattern) { pattern in
                FavoritePatternEditView(
                    pattern: pattern,
                    memo: $editingMemo,
                    favoriteService: favoriteService
                )
            }
            .sheet(isPresented: $showingAnalysis) {
                FavoriteDetailedAnalysisView(favoriteService: favoriteService)
            }
        }
    }
}

// MARK: - Tab Selector

struct FavoriteTabSelector: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            FavoriteTabButton(
                title: "パターン",
                icon: "heart.fill",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            FavoriteTabButton(
                title: "分析",
                icon: "chart.bar.fill",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
        }
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct FavoriteTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentGradient)
                } else {
                    Color.clear
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Favorite Patterns List

struct FavoritePatternsList: View {
    var favoriteService: FavoritePatternService
    @Binding var editingPattern: FavoritePattern?
    @Binding var editingMemo: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        if favoriteService.favoritePatterns.isEmpty {
            EmptyFavoritesView()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(favoriteService.favoritePatterns, id: \.createdAt) { pattern in
                        FavoritePatternCard(
                            pattern: pattern,
                            favoriteService: favoriteService,
                            onEdit: {
                                editingMemo = pattern.memo
                                editingPattern = pattern
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("お気に入りがありません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("生成したパターンのハートボタンを\nタップしてお気に入りに追加できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Favorite Pattern Card

struct FavoritePatternCard: View {
    let pattern: FavoritePattern
    var favoriteService: FavoritePatternService
    let onEdit: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("作成日時")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(pattern.createdAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if pattern.isWinning {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                }
                
                Menu {
                    Button("編集", systemImage: "pencil") {
                        onEdit()
                    }
                    
                    Button("当選マーク", systemImage: pattern.isWinning ? "crown.fill" : "crown") {
                        favoriteService.markAsWinning(pattern, isWinning: !pattern.isWinning)
                    }
                    
                    Button("削除", systemImage: "trash", role: .destructive) {
                        favoriteService.removeFavorite(pattern)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentGradient)
                }
            }
            
            // 数字パターン
            HStack(spacing: 8) {
                ForEach(pattern.numbers, id: \.self) { number in
                    FavoriteNumberBadge(
                        number: number,
                        frequency: favoriteService.getNumberFrequency(number),
                        maxFrequency: favoriteService.getMaxFrequency()
                    )
                }
            }
            
            // 統計情報
            FavoritePatternStatsView(pattern: pattern)
            
            // メモ
            if !pattern.memo.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                    Text(pattern.memo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
    }
}

// MARK: - Number Badge with Frequency

struct FavoriteNumberBadge: View {
    let number: Int
    let frequency: Int
    let maxFrequency: Int
    
    private var intensityColor: Color {
        guard maxFrequency > 0 else { return Color.accentColor.opacity(0.3) }
        
        let intensity = Double(frequency) / Double(maxFrequency)
        return Color.accentColor.opacity(0.3 + intensity * 0.7)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(number)")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
                .background(intensityColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            
            if frequency > 0 {
                Text("\(frequency)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Pattern Statistics

struct FavoritePatternStatsView: View {
    let pattern: FavoritePattern
    
    var body: some View {
        HStack(spacing: 20) {
            FavoriteStatItem(label: "1-21", value: "\(pattern.lowRangeCount)")
            FavoriteStatItem(label: "22-43", value: "\(pattern.highRangeCount)")
            FavoriteStatItem(label: "奇数", value: "\(pattern.oddCount)")
            FavoriteStatItem(label: "40+", value: "\(pattern.over40Count)")
            FavoriteStatItem(label: "連続", value: "\(pattern.consecutivePairs)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FavoriteStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Pattern Edit View

struct FavoritePatternEditView: View {
    let pattern: FavoritePattern
    @Binding var memo: String
    var favoriteService: FavoritePatternService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // パターン表示
                VStack(spacing: 12) {
                    Text("パターン")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(pattern.numbers, id: \.self) { number in
                            Text("\(number)")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(Color.accentGradient)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // メモ編集
                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ")
                        .font(.headline)
                    
                    TextField("メモを入力...", text: $memo, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("パターン編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        favoriteService.updateMemo(for: pattern, memo: memo)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Analysis Views

struct FavoriteAnalysisView: View {
    var favoriteService: FavoritePatternService
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        if favoriteService.favoritePatterns.isEmpty {
            EmptyAnalysisView()
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本統計
                    BasicAnalysisCard(favoriteService: favoriteService)
                    
                    // 数字頻度
                    NumberFrequencyCard(favoriteService: favoriteService)
                    
                    // 最頻出・最低頻度
                    FrequencyComparisonCard(favoriteService: favoriteService)
                }
                .padding()
            }
        }
    }
}

struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("分析データがありません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("お気に入りパターンを追加すると\n分析結果が表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BasicAnalysisCard: View {
    var favoriteService: FavoritePatternService
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("基本統計")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Color.accentGradient)
            }
            
            let patterns = favoriteService.favoritePatterns
            let allNumbers = patterns.flatMap { $0.numbers }
            let uniqueNumbers = Set(allNumbers).count
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(patterns.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.accentGradient)
                    Text("総パターン数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(uniqueNumbers)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("ユニーク数字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(43 - uniqueNumbers)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("未使用数字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
}

struct NumberFrequencyCard: View {
    var favoriteService: FavoritePatternService
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("数字使用頻度")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "number.circle.fill")
                    .foregroundStyle(Color.accentGradient)
            }
            
            // トップ使用数字
            let frequencyData = favoriteService.duplicateAnalysis.numberFrequency
            let topNumbers = frequencyData.sorted { $0.value > $1.value }.prefix(10)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(Array(topNumbers), id: \.key) { number, frequency in
                    VStack(spacing: 4) {
                        Text("\(number)")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        Text("\(frequency)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
}

struct FrequencyComparisonCard: View {
    var favoriteService: FavoritePatternService
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("頻度比較")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .foregroundStyle(Color.accentGradient)
            }
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("最頻出")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    let mostFrequent = favoriteService.getMostFrequentNumbers()
                    if !mostFrequent.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(mostFrequent.prefix(5), id: \.self) { number in
                                Text("\(number)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24, height: 24)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack(spacing: 8) {
                    Text("最低頻度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    let leastFrequent = favoriteService.getLeastFrequentNumbers()
                    if !leastFrequent.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(leastFrequent.prefix(5), id: \.self) { number in
                                Text("\(number)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24, height: 24)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
}

struct FavoriteDetailedAnalysisView: View {
    var favoriteService: FavoritePatternService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("詳細分析機能は開発中です")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                    
                    Text("今後のアップデートで\nより詳細な分析機能を追加予定です")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("詳細分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accentGradient)
                }
            }
        }
    }
}

#Preview {
    let schema = Schema([FavoritePattern.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        let service = FavoritePatternService(modelContext: container.mainContext)
        
        // サンプルデータを追加
        _ = service.addFavorite([1, 15, 23, 34, 41, 43], memo: "サンプルパターン1")
        _ = service.addFavorite([5, 12, 18, 25, 38, 42], memo: "サンプルパターン2")
        
        return FavoritesView(favoriteService: service)
    } catch {
        return Text("プレビューエラー: \(error.localizedDescription)")
    }
}
