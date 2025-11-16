# Claude Code 開発メモ

DBへのマイグレーションやdeleteは確認なしで行わないでください。
追加修正したものは `/docs` ディレクトリにまとめてください。


このファイルは、Claude Codeによる開発の履歴と重要なアーキテクチャ情報をまとめたものです。

## ドキュメント

プロジェクトの詳細なドキュメントは `/docs` ディレクトリにあります:

- **[ワークフローノード設定フォームの共通化](/docs/workflow-form-unification.md)** - ノード設定UIの統一アーキテクチャ

## 最近の主要な変更

### 2025-01-16: ワークフロー実行のAPI経由化とビルドエラー修正

**目的**: Client Component から Node.js モジュールを直接インポートすることによるビルドエラーを解決し、ワークフロー実行を適切にAPI経由で行う

**変更内容**:
- `/app/api/workflows/execute-draft/route.ts` を新規作成し、現在編集中のワークフローを実行するAPIエンドポイントを追加
- `/components/workflow/ExecutionPanel.tsx` を修正し、`executor.ts` の直接インポートを削除、API経由で実行するように変更
- `/next.config.ts` に Turbopack 設定と `serverExternalPackages` を追加し、Node.js モジュールのバンドルエラーを解決
- `/components/workflow/ElevenLabsNodeSettings.tsx` を `UnifiedNodeSettings` を使用するように簡素化（約370行 → 約20行）
- TypeScript エラーを修正（`lib/elevenlabs/constants.ts`, `app/api/workflows/execute/route.ts`, `lib/workflow/executor.ts`）

**技術的詳細**:
- Client Component から `@google-cloud/storage`, `pg` などの Node.js 専用モジュールを間接的にインポートしていたため、Turbopack ビルドで `child_process`, `fs`, `dns` などが解決できないエラーが発生
- `serverExternalPackages` 設定により、これらのパッケージをサーバーサイド専用として扱うように指定
- webpack の fallback 設定で、クライアントサイドでは Node.js モジュールを `false` に設定

**影響範囲**:
- ワークフロー実行がAPI経由になったため、サーバーサイドで適切に Node.js 機能を使用可能
- ビルドが成功し、本番環境へのデプロイが可能に
- ExecutionPanel の実行フローは維持されつつ、アーキテクチャが改善

### 2025-01-XX: ワークフローノード設定フォームの共通化

**目的**: コードの重複を削減し、保守性と拡張性を向上

**変更内容**:
- `/lib/workflow/formConfigGenerator.ts` に `getNodeTypeConfig()` を追加し、各ノードタイプの設定を一元管理
- `/components/form/DynamicFormField.tsx` に `slider` と `switch` フィールドタイプを追加
- `/components/workflow/UnifiedNodeSettings.tsx` を作成し、全ノードタイプで共通使用可能な設定UIを実装
- 各ノード設定コンポーネント（Gemini, ElevenLabs, Nanobana, Higgsfield, ImageInput）を簡素化（約300-700行 → 約20-25行）

**影響範囲**:
- 新しいノードタイプの追加が容易に（設定ファイルへの追加のみ）
- UIの一貫性向上
- バグ修正が一箇所で完結

**詳細**: [workflow-form-unification.md](/docs/workflow-form-unification.md)

---

## アーキテクチャの原則

### 設定の一元管理
- ノード設定は `/lib/workflow/formConfigGenerator.ts` で一元管理
- UIコンポーネントは設定に基づいて動的に生成

### コンポーネントの再利用
- 共通のUIパターンは `DynamicFormField` で実装
- ノード固有のロジックは最小限に

### データの整合性
- 画像データは GCP Storage に保存し、`storagePath` で参照
- 一部の既存実装（Nanobana の `referenceImages`）は後方互換性のため例外的に base64 形式を保持

---

## 開発ガイドライン

### 新しいノードタイプの追加

1. `/lib/workflow/formConfigGenerator.ts` の `getNodeTypeConfig()` に設定を追加
2. `/components/workflow/XxxNodeSettings.tsx` を作成（UnifiedNodeSettings をラップ）
3. 必要に応じてデフォルト値を `UnifiedNodeSettings.tsx` に追加

詳細は [workflow-form-unification.md](/docs/workflow-form-unification.md#新しいノードタイプの追加方法) を参照。

### 新しいフィールドタイプの追加

1. `FormFieldConfig` インターフェースに型を追加
2. `DynamicFormField.tsx` にレンダリングロジックを実装

詳細は [workflow-form-unification.md](/docs/workflow-form-unification.md#dynamicformfieldの拡張) を参照。

---

## 注意事項

- **データベース操作**: マイグレーションや削除は慎重に。確認なしで実行しない。
- **後方互換性**: 既存のワークフローデータとの互換性を維持すること。
- **画像データ**: 新規実装では `storagePath` ベースを推奨。既存データの移行は段階的に。

---

## 参考資料

- [README.md](/README.md) - プロジェクト概要
- [QUICKSTART.md](/QUICKSTART.md) - クイックスタートガイド
- [DATABASE.md](/DATABASE.md) - データベーススキーマ
- [AUTHENTICATION.md](/AUTHENTICATION.md) - 認証システム
