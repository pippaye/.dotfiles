#!/usr/bin/env bash
set -euo pipefail

die() {
    printf '错误: %s\n' "$*" >&2
    exit 1
}

check_dependencies() {
    local missing=()
    local cmd

    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "缺少依赖: ${missing[*]}"
    fi
}

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

check_dependencies

API_BASE="${BASE_URL%/}/api/v1"

# ---- 获取分组 ID ----
GROUP_IDS_JSON="[]"
if [[ -n "$GROUP_NAME" ]]; then
    echo ">>> 查询分组: $GROUP_NAME"

    GROUPS_RESP=$(curl -s -X GET "${API_BASE}/admin/groups/all" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json")

    GROUP_ID_JSON="$(
        jq -ce --arg name "$GROUP_NAME" '
          (.data? // .) as $groups
          | if ($groups | type) == "array" then
              ([$groups[] | select(.name == $name) | .id] | first // empty)
            else
              empty
            end
        ' <<<"$GROUPS_RESP" 2>/dev/null || true
    )"

    if [[ -z "$GROUP_ID_JSON" ]]; then
        # 列出所有分组帮助排查
        echo "错误: 未找到分组 '$GROUP_NAME'"
        echo "可用分组:"
        AVAILABLE_GROUPS="$(jq -r '
          (.data? // .) as $groups
          | if ($groups | type) == "array" then
              $groups[] | "  id=\(.id)  name=\(.name)"
            else
              empty
            end
        ' <<<"$GROUPS_RESP" 2>/dev/null || true)"
        if [[ -n "$AVAILABLE_GROUPS" ]]; then
            echo "$AVAILABLE_GROUPS"
        else
            echo "$GROUPS_RESP"
        fi
        exit 1
    fi

    GROUP_IDS_JSON="[$GROUP_ID_JSON]"
    GROUP_ID="$(jq -r '.' <<<"$GROUP_ID_JSON")"
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
        -d "$(
            jq -nc \
                --rawfile content "$f" \
                --arg name "${BASENAME%.*}" \
                --argjson group_ids "$GROUP_IDS_JSON" \
                '{
                  content: ($content | gsub("^\\s+|\\s+$"; "")),
                  name: $name,
                  group_ids: $group_ids,
                  skip_default_group_bind: true
                }'
        )")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "  HTTP $HTTP_CODE"

    SUMMARY=$(jq -r '
      (.data // {}) as $d
      | "  总计=\($d.total // 0) 新建=\($d.created // 0) 更新=\($d.updated // 0) 失败=\($d.failed // 0)",
        (($d.errors // [])[]? | "  [\(.index // "")] \(.message // "")")
    ' <<<"$BODY" 2>/dev/null) || SUMMARY="$BODY"

    echo "$SUMMARY"
    echo ""
done

echo "完成。"
