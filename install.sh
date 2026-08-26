#!/usr/bin/env bash
# iny-build 설치
# 사용법:  bash install.sh [작업폴더경로]
#          경로를 안 주면 01·02·03·04 에서 쓰던 폴더를 그대로 씁니다.
#
# 변수 이름은 영문만 씁니다. zsh 는 한글 변수를 받지만 bash 는 못 받고,
# bash -n 문법 검사는 통과해서 실행해야 잡힙니다.
set -e
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.claude/iny-config.json"

# 앞 단계가 이미 잡아둔 작업 폴더를 그대로 쓴다. 덮어쓰면 앞 단계가 만든 것을 못 찾는다.
EXISTING=""
if [ -f "$CONFIG" ]; then
  EXISTING="$(sed -n 's/.*"kb_path"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$CONFIG" | head -1)"
fi

KB_PATH="${1:-${EXISTING:-$HOME/asset-engine}}"
KB_PATH="${KB_PATH/#\~/$HOME}"

mkdir -p "$KB_PATH/outputs"
mkdir -p "$HOME/.claude"
cat > "$CONFIG" <<CFG
{
  "kb_path": "$KB_PATH"
}
CFG

DEST="$HOME/.claude/skills/iny-build"
mkdir -p "$DEST"
cp "$SRC/SKILL.md" "$DEST/SKILL.md"
rm -rf "$DEST/scripts" "$DEST/references"
cp -R "$SRC/scripts" "$DEST/scripts"          # 올린 주소를 받아봐서 재는 것
cp -R "$SRC/references" "$DEST/references"    # 짓는규칙 · 근거와 한계 · 산출물 양식

echo
echo "설치됐습니다."
echo "  스킬      ~/.claude/skills/iny-build/"
echo "  작업 폴더  $KB_PATH"

# 05 는 04 가 그린 화면을 실제로 짓는 단계입니다. 없으면 여기서 알려주고 멈춥니다.
if [ ! -f "$KB_PATH/outputs/04-design/화면설계서.html" ]; then
  echo
  echo "다만 04 에서 만든 화면설계서가 안 보입니다."
  echo "05 는 04 가 그린 화면을 실제로 짓는 단계라 04 를 먼저 하셔야 합니다."
  echo "  https://github.com/iny101400-young/iny-design"
  exit 0
fi

echo
echo "Claude Code 를 $KB_PATH 에서 열고 '사이트 짓기' 라고 치세요."
