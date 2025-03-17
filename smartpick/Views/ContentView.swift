import SwiftUI

struct ContentView: View {
    @State private var selectedNumbers: Set<Int> = []
    @State private var conditions = LotoConditions()
    @State private var requestedPatternCount = 5
    @State private var generatedPatterns: [[Int]] = []
    @State private var isGenerating = false
    @State private var showingConditionSettings = false
    @State private var showingHelp = false
    @State private var alert: AlertType?
    @Environment(\.colorScheme) private var colorScheme
    
    private let patternCountOptions = [1, 3, 5, 10]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    
    // アクセントカラー
    private var accentColor: Color {
        Color.blue
    }
    
    // テキストカラー
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    // 背景カラー
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)
    }
    
    // 選択背景カラー
    private var selectionColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // タイトル
                    Text("SmartPick")
                        .font(.system(size: 36, weight: .bold))
                        .padding(.vertical, 16)
                        .foregroundColor(accentColor)
                    
                    // 数字選択セクション
                    VStack(spacing: 12) {
                        HStack {
                            Text("数字を選択")
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                            
                            Spacer()
                            
                            // 全選択・リセットボタン
                            HStack(spacing: 12) {
                                Button(action: {
                                    selectedNumbers = Set(1...43)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("全選択")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(accentColor)
                                }
                                
                                Button(action: {
                                    selectedNumbers.removeAll()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("リセット")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 数字選択グリッド
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(1...43, id: \.self) { number in
                                NumberButton(
                                    number: number,
                                    isSelected: .init(
                                        get: { selectedNumbers.contains(number) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedNumbers.insert(number)
                                            } else {
                                                selectedNumbers.remove(number)
                                            }
                                        }
                                    ),
                                    selectionColor: selectionColor,
                                    backgroundColor: backgroundColor
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // パターン数選択セクション
                    VStack(alignment: .leading, spacing: 12) {
                        Text("生成パターン数")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)
                        
                        HStack(spacing: 12) {
                            ForEach(patternCountOptions, id: \.self) { count in
                                Button(action: {
                                    requestedPatternCount = count
                                }) {
                                    Text("\(count)")
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(requestedPatternCount == count ? selectionColor : backgroundColor)
                                        )
                                        .foregroundColor(requestedPatternCount == count ? .white : primaryTextColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 生成ボタン
                    Button(action: {
                        Task {
                            await generatePatterns()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("パターンを生成")
                                .font(.system(size: 18, weight: .medium))
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)
                    
                    // 生成結果
                    if !generatedPatterns.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("生成結果")
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                                .padding(.horizontal)
                            
                            ForEach(generatedPatterns.indices, id: \.self) { index in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("パターン \(index + 1)")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        HStack(spacing: 8) {
                                            ForEach(generatedPatterns[index].sorted(), id: \.self) { number in
                                                Text("\(number)")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .frame(width: 36, height: 36)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(backgroundColor)
                                                    )
                                                    .foregroundColor(primaryTextColor)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    if index < generatedPatterns.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingConditionSettings = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingConditionSettings) {
                ConditionSettingsView(conditions: $conditions)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .customAlert(alert: $alert)
        }
    }
    
    private func generatePatterns() async {
        guard validateInputNumbers() else { return }
        
        isGenerating = true
        generatedPatterns = []
        
        do {
            let generator = PatternGenerator(
                selectedNumbers: selectedNumbers,
                conditions: conditions,
                requestedPatternCount: requestedPatternCount
            )
            
            let patterns = await generator.generate()
            
            if patterns.isEmpty {
                alert = AlertType(
                    title: "パターンが見つかりません",
                    message: "条件を緩和するか、数字の選択を見直してください",
                    type: .warning
                )
            } else {
                generatedPatterns = patterns
            }
        }
        
        isGenerating = false
    }
    
    private func validateInputNumbers() -> Bool {
        if selectedNumbers.count < 6 {
            alert = AlertType(
                title: "数字が不足しています",
                message: "最低6個の数字を選択してください",
                type: .error
            )
            return false
        }
        
        let lowRangeCount = selectedNumbers.filter { $0 <= 21 }.count
        let highRangeCount = selectedNumbers.filter { $0 > 21 }.count
        
        if conditions.lowRangeCount >= 0 && lowRangeCount < conditions.lowRangeCount {
            alert = AlertType(
                title: "1〜21の数字が不足しています",
                message: "条件を満たすために必要な数の数字を選択してください",
                type: .error
            )
            return false
        }
        
        if conditions.highRangeCount >= 0 && highRangeCount < conditions.highRangeCount {
            alert = AlertType(
                title: "22〜43の数字が不足しています",
                message: "条件を満たすために必要な数の数字を選択してください",
                type: .error
            )
            return false
        }
        
        return true
    }
}

#Preview {
    ContentView()
} 
