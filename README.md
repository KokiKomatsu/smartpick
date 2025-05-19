# SmartPick

SmartPickは宝くじの番号を最適化して生成するiOSアプリケーションです。ユーザーが選択した数字の中から、特定の条件（奇数/偶数の数、低範囲/高範囲の数字数、連続ペア数など）に基づいて最適な組み合わせを生成します。

[English version below](#smartpick-1)

## 機能

- 数字選択グリッド（1-43）で宝くじ番号を選択
- 詳細な条件設定による番号パターン生成の最適化:
  - 40以上の数字の上限設定
  - 連続ペア数の指定
  - 1〜21の数字の数の指定
  - 奇数の数の指定
  - パターン間共通数字の上限設定
- 複数パターンの同時生成（1, 3, 5, 10パターン）
- 最適化されたアルゴリズムによる効率的なパターン生成
  - ランダム生成アルゴリズム
  - バックトラッキングアルゴリズム

## 要件

- iOS 17.6以上
- Swift 5.0
- Xcode 16.2以上

## 使い方

1. グリッドから数字を選択（最低6個必要）
2. 必要に応じて条件を設定（ナビゲーションバーの設定アイコンをタップ）
3. 生成したいパターン数を選択（1, 3, 5, 10）
4. 「パターンを生成」ボタンをタップ

生成されたパターンはスクロール可能なリストに表示されます。

## 技術的な詳細

SmartPickはSwiftUIで構築されており、高効率なパターン生成のためにSwiftの最新機能を活用しています。パターン生成エンジンは以下の2つの主要アルゴリズムを実装しています：

1. **ランダム生成アルゴリズム**: シンプルなケース向けに最適化されたランダム選択方式
2. **最適化バックトラッキングアルゴリズム**: 複雑な条件下での効率的な組み合わせ生成

マルチコア処理を活用した並列処理により、複雑な条件下でも高速にパターンを生成します。

---

# SmartPick

SmartPick is an iOS application designed to generate optimized lottery number combinations. It creates patterns from user-selected numbers based on specific constraints (such as odd/even count, low/high range numbers, consecutive pairs, etc.).

## Features

- Number selection grid (1-43) for lottery numbers
- Detailed constraint settings for pattern optimization:
  - Limit on numbers above 40
  - Consecutive pair count specification
  - Number of low range (1-21) numbers
  - Odd number count specification
  - Limit on common numbers between patterns
- Multiple pattern generation (1, 3, 5, 10 patterns)
- Efficient pattern generation with optimized algorithms:
  - Random generation algorithm
  - Backtracking algorithm

## Requirements

- iOS 17.6 or later
- Swift 5.0
- Xcode 16.2 or later

## Usage

1. Select numbers from the grid (minimum 6 numbers required)
2. Configure constraints as needed (tap the settings icon in the navigation bar)
3. Choose the number of patterns to generate (1, 3, 5, 10)
4. Tap the "Generate Patterns" button

Generated patterns will be displayed in a scrollable list.

## Technical Details

SmartPick is built with SwiftUI and leverages Swift's latest features for efficient pattern generation. The pattern generation engine implements two main algorithms:

1. **Random Generation Algorithm**: Optimized random selection method for simpler cases
2. **Optimized Backtracking Algorithm**: Efficient combination generation under complex constraints

The app utilizes parallel processing with multi-core utilization to generate patterns quickly even under complex constraints.
