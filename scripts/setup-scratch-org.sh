#!/bin/bash
set -euo pipefail

# =============================================================================
# setup-scratch-org.sh
# ScratchOrgの作成からコンポーネントデプロイまでを一括実行するスクリプト
# =============================================================================

# スクリプトの場所に関わらずプロジェクトルートから実行する
cd "$(dirname "$0")/.."

ALIAS="chatter-expanded-dev"
DURATION_DAYS=7

echo "========================================"
echo "  Chatter Expanded - ScratchOrg Setup"
echo "========================================"

# 1. Dev Hub への認証確認
echo ""
echo "[1/5] Dev Hub への認証確認..."
DEVHUB_USERNAME=$(sf config get target-dev-hub --json 2>/dev/null | jq -r '.result[0].value // empty' 2>/dev/null || true)
if [ -z "${DEVHUB_USERNAME}" ]; then
  echo "  Default Dev Hub が設定されていません。以下のコマンドで認証・設定してください:"
  echo "  sf org login web --set-default-dev-hub"
  exit 1
fi
echo "  OK (Dev Hub: ${DEVHUB_USERNAME})"

# 2. ScratchOrg の作成
echo ""
echo "[2/5] ScratchOrg を作成中 (alias: ${ALIAS}, duration: ${DURATION_DAYS}日)..."
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias "${ALIAS}" \
  --duration-days "${DURATION_DAYS}" \
  --set-default \
  --wait 10
echo "  OK"

# 3. ソースのデプロイ
echo ""
echo "[3/5] ソースをデプロイ中..."
sf project deploy start \
  --source-dir force-app \
  --wait 10
echo "  OK"

# 4. Apex テストの実行
echo ""
echo "[4/5] Apex テストを実行中..."
sf apex run test \
  --test-level RunLocalTests \
  --wait 10 \
  --result-format human
echo "  OK"

# 5. 完了
echo ""
echo "[5/5] セットアップ完了!"
echo ""
echo "========================================"
echo "  次のステップ（動作確認）"
echo "========================================"
echo ""
echo "1. 以下のコマンドで ScratchOrg をブラウザで開く:"
echo "   ./scripts/open-org.sh"
echo ""
echo "2. App Builder でコンポーネントをページに追加:"
echo "   設定 > Lightning App Builder > 新規ページ作成（またはホームページ編集）"
echo "   コンポーネントパネルから [Chatter Feed（全文表示）] を追加"
echo ""
echo "3. Salesforce モバイルアプリで確認:"
echo "   モバイルアプリを開き、追加したページを表示"
echo "   長文Chatter投稿が折りたたまれずに表示されることを確認"
echo ""
