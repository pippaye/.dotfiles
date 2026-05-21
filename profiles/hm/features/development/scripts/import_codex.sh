#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
用法: import_codex --base-url <URL> --auth-token <TOKEN> [--group-name <NAME>] <FILE>...

选项:
  --base-url <URL>       Sub2API 服务地址，如 http://localhost:8080
  --auth-token <TOKEN>   Admin JWT Token
  --group-name <NAME>    目标分组名称，自动查 ID

参数:
  <FILE>...              一个或多个 Codex Session JSON 文件

示例:
  import_codex --base-url http://localhost:8080 --auth-token eyJ... --group-name "Plus账号" *.json

Token 获取: 浏览器控制台 → localStorage.getItem('auth_token')
EOF
    exit 1
}

# ---- 解析参数 ----
BASE_URL=""
AUTH_TOKEN=""
GROUP_NAME=""
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url)     BASE_URL="$2"; shift 2 ;;
        --auth-token)   AUTH_TOKEN="$2"; shift 2 ;;
        --group-name)   GROUP_NAME="$2"; shift 2 ;;
        --help|-h)      usage ;;
        *)              FILES+=("$1"); shift ;;
    esac
done

if [[ -z "$BASE_URL" || -z "$AUTH_TOKEN" || ${#FILES[@]} -eq 0 ]]; then
    usage
fi

API_BASE="${BASE_URL%/}/api/v1"

# ---- 获取分组 ID ----
GROUP_IDS_JSON="[]"
if [[ -n "$GROUP_NAME" ]]; then
    echo ">>> 查询分组: $GROUP_NAME"

    GROUPS_RESP=$(curl -s -X GET "${API_BASE}/admin/groups/all" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json")

    GROUP_ID=$(echo "$GROUPS_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
groups = data.get('data', data) if isinstance(data, dict) else data
for g in groups:
    if g.get('name') == '${GROUP_NAME}':
        print(g['id'])
        break
" 2>/dev/null)

    if [[ -z "$GROUP_ID" ]]; then
        # 列出所有分组帮助排查
        echo "错误: 未找到分组 '$GROUP_NAME'"
        echo "可用分组:"
        echo "$GROUPS_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
groups = data.get('data', data) if isinstance(data, dict) else data
for g in groups:
    print(f'  id={g[\"id\"]}  name={g[\"name\"]}')
" 2>/dev/null || echo "$GROUPS_RESP"
        exit 1
    fi

    GROUP_IDS_JSON="[$GROUP_ID]"
    echo ">>> 分组ID: $GROUP_ID"
    echo ""
fi

# ---- 导入文件 ----
IMPORT_URL="${API_BASE}/admin/accounts/import/codex-session"

for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || { echo "跳过: 文件不存在 $f"; continue; }

    BASENAME=$(basename "$f")
    echo ">>> 导入: $BASENAME"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$IMPORT_URL" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$(python3 -c "
import json, sys
payload = {
    'content': open(sys.argv[1]).read().strip(),
    'name': sys.argv[2],
    'group_ids': json.loads(sys.argv[3]),
    'skip_default_group_bind': True,
}
print(json.dumps(payload, ensure_ascii=False))
" "$f" "${BASENAME%.*}" "$GROUP_IDS_JSON")")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "  HTTP $HTTP_CODE"

    SUMMARY=$(echo "$BODY" | python3 -c "
import sys, json
d = json.load(sys.stdin).get('data', {})
print(f'  总计={d.get(\"total\",0)} 新建={d.get(\"created\",0)} 更新={d.get(\"updated\",0)} 失败={d.get(\"failed\",0)}')
if d.get('errors'):
    for e in d['errors']:
        print(f'  [{e.get(\"index\")}] {e.get(\"message\")}')
" 2>/dev/null) || echo "$BODY"

    echo "$SUMMARY"
    echo ""
done

echo "完成。"