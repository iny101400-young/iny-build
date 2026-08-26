#!/usr/bin/env bash
# 받아보기 · 05 BUILD
#
# 올린 사이트를 실제로 받아서 항목별로 잰다.
# 맥에 이미 있는 curl 만 쓴다. 아무것도 더 깔지 않는다.
#
#   bash 받아보기.sh https://내가올린주소
#   bash 받아보기.sh https://내가올린주소 --봇
#
# --봇 을 붙이면 로봇 이름으로도 받아본다. 앞단에서 막히는지 본다.
#
# ★ 파일을 보는 것과 받아보는 것은 다르다.
#    파일에는 다 맞게 적혀 있는데 앞단에서 막히는 일이 05 에서 제일 흔하다.
#
# 변수 이름은 영문만 쓴다. zsh 는 한글 변수를 받지만 bash 는 못 받고,
# bash -n 문법 검사는 통과해서 실행해야 잡힌다.

set -u

URL="${1:-}"
BOTS="${2:-}"

if [ -z "$URL" ]; then
  echo "쓰는 법:  bash 받아보기.sh {주소} [--봇]"
  echo "예:      bash 받아보기.sh https://example.com"
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "✕ 이 컴퓨터에 curl 이 없습니다."
  exit 3
fi

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
URL="${URL%/}"

# 한글은 글자 폭이 달라 칸 맞추기가 어긋난다. 표시를 앞에 두면 저절로 맞는다.
say() { printf "  %s  %s\n" "$1" "$2"; }

# ── 받아온다 ──────────────────────────────────────────────
HEAD="$(curl -sI -A "$UA" -L --max-time 15 "$URL" 2>/dev/null)"
BODY="$(curl -s  -A "$UA" -L --max-time 15 "$URL" 2>/dev/null)"
CODE="$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" -L --max-time 15 "$URL" 2>/dev/null)"

if [ -z "$BODY" ]; then
  echo "✕ 아무것도 못 받았습니다.  응답 $CODE"
  echo "  주소가 맞는지, 배포가 끝났는지 확인하세요."
  exit 1
fi

echo
echo "── 받아본 곳"
say "·" "주소  $URL"
say "·" "응답  $CODE"
echo

# ── 앞단 · 여기가 제일 먼저다 ────────────────────────────
echo "── 앞단 (파일 안을 보기 전에 여기부터)"

NOINDEX="$(printf '%s' "$HEAD" | grep -i 'x-robots-tag' | head -1)"
if [ -n "$NOINDEX" ]; then
  case "$NOINDEX" in
    *noindex*|*NOINDEX*|*NoIndex*)
      say "✕" "검색 금지 머리글이 붙어 있습니다  ← 검색이 안 가져갑니다" ;;
    *)
      say "○" "검색 금지 머리글 없음 (다른 값이 붙어 있습니다)" ;;
  esac
else
  say "○" "검색 금지 머리글 없음"
fi

# 자바스크립트를 빼고 글자가 남는지 본다. 로봇은 기다리지 않는다.
TEXTLEN="$(printf '%s' "$BODY" \
  | sed -e 's/<script[^>]*>/\'$'\n''<SCRIPT>/g' -e 's#</script>#</SCRIPT>\'$'\n''#g' \
  | awk '/<SCRIPT>/{f=1} /<\/SCRIPT>/{f=0;next} !f' \
  | sed -e 's/<[^>]*>/ /g' -e 's/[[:space:]][[:space:]]*/ /g' \
  | tr -d '\n' | wc -c | tr -d ' ')"
if [ "$TEXTLEN" -gt 300 ]; then
  say "○" "자바스크립트 없이 글이 보입니다  약 ${TEXTLEN}자"
else
  say "✕" "자바스크립트 없이는 글이 거의 안 보입니다  약 ${TEXTLEN}자"
fi
echo

# ── 파일 넷 ──────────────────────────────────────────────
echo "── 파일"
for f in robots.txt sitemap.xml llms.txt; do
  c="$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" -L --max-time 10 "$URL/$f" 2>/dev/null)"
  if [ "$c" = "200" ]; then say "○" "$f 있습니다"; else say "✕" "$f 없습니다  ($c)"; fi
done
echo

# ── 화면에 붙은 것 ───────────────────────────────────────
echo "── 이 화면에 붙은 것"

TITLE="$(printf '%s' "$BODY" | tr -d '\n' | sed -n 's/.*<title[^>]*>\([^<]*\)<\/title>.*/\1/p' | head -1)"
[ -n "$TITLE" ] && say "○" "제목  $TITLE" || say "✕" "제목이 없습니다"

DESC="$(printf '%s' "$BODY" | tr -d '\n' | grep -o '<meta[^>]*name="description"[^>]*>' | head -1)"
[ -n "$DESC" ] && say "○" "두 줄 요약 있습니다" || say "✕" "두 줄 요약이 없습니다"

CANON="$(printf '%s' "$BODY" | tr -d '\n' | grep -o '<link[^>]*rel="canonical"[^>]*>' | head -1)"
[ -n "$CANON" ] && say "○" "대표 주소 있습니다" || say "✕" "대표 주소가 없습니다"

LANG="$(printf '%s' "$BODY" | grep -o '<html[^>]*lang="[^"]*"' | head -1 | sed 's/.*lang="\([^"]*\)".*/\1/')"
[ -n "$LANG" ] && say "○" "사이트 언어 표시  $LANG" || say "✕" "사이트 언어 표시가 없습니다"

H1="$(printf '%s' "$BODY" | grep -o '<h1' | wc -l | tr -d ' ')"
if [ "$H1" = "1" ]; then say "○" "큰 제목이 하나입니다"
elif [ "$H1" = "0" ]; then say "✕" "큰 제목이 없습니다"
else say "✕" "큰 제목이 ${H1}개입니다  ← 하나여야 합니다"; fi

LD="$(printf '%s' "$BODY" | grep -o 'application/ld+json' | wc -l | tr -d ' ')"
if [ "$LD" -gt 0 ]; then say "○" "기계가 읽는 표시  ${LD}개"; else say "✕" "기계가 읽는 표시가 0개입니다"; fi

OGI="$(printf '%s' "$BODY" | tr -d '\n' | grep -o '<meta[^>]*property="og:image"[^>]*content="[^"]*"' | head -1 | sed 's/.*content="\([^"]*\)".*/\1/')"
if [ -z "$OGI" ]; then
  say "✕" "나눌 때 뜨는 그림이 없습니다"
else
  case "$OGI" in
    http*) say "○" "나눌 때 뜨는 그림이 절대 주소입니다" ;;
    *)     say "✕" "나눌 때 뜨는 그림이 상대 주소입니다 ($OGI)  ← 절대 주소여야 뜹니다" ;;
  esac
fi
echo

# ── 로봇으로 받아본다 ────────────────────────────────────
if [ "$BOTS" = "--봇" ]; then
  echo "── 로봇 이름으로 받아보기 (앞단에서 막히나)"
  echo "   ※ 이름은 계속 바뀝니다. 지금 도는 이름인지 확인하고 고쳐 쓰세요."
  for b in "Googlebot" "GPTBot" "ClaudeBot" "PerplexityBot"; do
    c="$(curl -s -o /dev/null -w '%{http_code}' -A "$b" -L --max-time 12 "$URL" 2>/dev/null)"
    if [ "$c" = "200" ]; then say "○" "$b 들어와집니다"
    else say "✕" "$b 막힙니다  ($c)  ← 앞단 설정을 보세요"; fi
  done
  echo
fi

echo "★ 이 결과를 검사표에 그대로 옮기세요. 짐작해서 적지 않습니다."
echo "★ ✕ 가 있으면 고치고 다시 올린 뒤 다시 받아봅니다."
exit 0
