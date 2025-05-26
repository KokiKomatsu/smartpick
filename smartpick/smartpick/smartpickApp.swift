//
//  smartpickApp.swift
//  smartpick
//
//  Created by Koki Komatsu on 2025/03/03.
//

import SwiftUI
import SwiftData

@main
struct smartpickApp: App {
    // モデルコンテナを保持するプロパティ
    let modelContainer: ModelContainer
    
    // 初期化時にモデルコンテナを作成
    init() {
        print("アプリ初期化を開始")
        // FavoritePatternモデルをスキーマに追加
        let schema = Schema([FavoritePattern.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            print("ModelContainerを正常に作成")
        } catch {
            print("ModelContainer作成に失敗: \(error)")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("メモリ内ModelContainerを作成")
            } catch {
                fatalError("モデルコンテナの作成に完全に失敗: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // TabViewからFavoritesViewを削除
            ContentView()
                .tabItem {
                    Label("パターン生成", systemImage: "dice")
                }
        }
        .modelContainer(modelContainer)
    }
}


