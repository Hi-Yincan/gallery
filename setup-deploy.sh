#!/usr/bin/env bash
# ============================================================
# 摄影站部署初始化脚本
# 功能:配置 secrets → 触发构建 → 启用 Pages → 等待上线
# 用法:填好下方 PAT 后执行  ./setup-deploy.sh
# ============================================================
set -euo pipefail

# ================= 变量置顶 =================
# PAT 不写入本文件(公开仓库会被 GitHub 拦截)。
# 读取顺序:环境变量 PAT > ~/gallery/.deploy.env > 交互输入
# 创建:https://github.com/settings/tokens/new (scope 勾选 repo)
SITE_REPO="Hi-Yincan/gallery"           # 主体仓库(公开)
CONTENT_REPO="Hi-Yincan/gallery-content" # 内容仓库(私有)
# ============================================

if [ -z "${PAT:-}" ] && [ -f "$(dirname "$0")/.deploy.env" ]; then
  # shellcheck disable=SC1091
  source "$(dirname "$0")/.deploy.env"
fi
if [ -z "${PAT:-}" ]; then
  read -r -s -p "请输入 PAT:" PAT
  echo
fi

[ -z "$PAT" ] && { echo "❌ 请先在脚本顶部填入 PAT"; exit 1; }
command -v gh >/dev/null || { echo "❌ 需要 gh CLI"; exit 1; }

SITE_URL="https://${SITE_REPO%/*}.github.io/${SITE_REPO#*/}/"

# 1. 配置 secrets
echo "==> 配置 secrets..."
gh secret set PAT -R "$SITE_REPO" --body "$PAT"
gh secret set DISPATCH_TOKEN -R "$CONTENT_REPO" --body "$PAT"

# 2. 触发部署 workflow
echo "==> 触发部署 workflow..."
gh workflow run deploy -R "$SITE_REPO"

# 3. 等待 gh-pages 分支出现(首次构建完成)
echo "==> 等待首次构建(约 2-3 分钟)..."
for i in $(seq 1 30); do
  sleep 10
  if gh api "repos/$SITE_REPO/branches/gh-pages" --jq '.name' >/dev/null 2>&1; then
    echo "   gh-pages 分支已生成"
    break
  fi
  echo "   第 $((i*10)) 秒,构建中..."
done

# 4. 启用 GitHub Pages(gh-pages 分支)
echo "==> 启用 GitHub Pages..."
gh api -X POST "repos/$SITE_REPO/pages" \
  -f "source[branch]=gh-pages" -f "source[path]=/" \
  --jq '.html_url' 2>/dev/null || echo "(Pages 可能已启用,或稍后手动设置)"

# 5. 等待站点 200
echo "==> 等待站点上线: $SITE_URL"
for i in $(seq 1 12); do
  sleep 10
  code=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL" || true)
  echo "   第 $((i*10)) 秒 → HTTP $code"
  [ "$code" = "200" ] && break
done

echo
[ "$code" = "200" ] && echo "✅ 站点已上线: $SITE_URL" || echo "⚠️ 站点暂未就绪,稍后手动访问: $SITE_URL"
echo "ℹ️  后续更新:改完内容 push 到内容仓库即可,CI 自动重建部署"
