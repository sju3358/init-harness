#!/bin/sh
# 프로젝트에 설치된 하네스를 새 하네스 버전으로 갱신
# 하네스 파일은 3-way 병합(기준 버전 ↔ 프로젝트 현재 ↔ 새 버전)이라 프로젝트에서 고친 내용 보존
# .harness/seed 목록(프로젝트가 채운 문서)은 없을 때만 추가하고, 템플릿 변경은 diff만 남김
# 커밋은 하지 않음. 결과 보고와 충돌 목록은 .harness/update/report.txt
#
# 사용법 (프로젝트 루트에서): sh <하네스 저장소>/.harness/update.sh <기준 커밋|-> <하네스 저장소 경로>
#   기준 커밋을 `-`로 주면 프로젝트의 .harness/version 값 사용

set -u
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "git 저장소에서 실행"; exit 2; }
cd "$root" || exit 2

base=${1:--}
src=${2:-}
[ "$base" = - ] && base=$(cat .harness/version 2>/dev/null)
[ -n "$base" ] || { echo "기준 버전 없음. .harness/version이 없으면 설치 당시 하네스 커밋을 인자로 지정"; exit 2; }
[ -n "$src" ] && [ -d "$src/.git" ] || { echo "하네스 저장소 경로를 지정"; exit 2; }
[ "$(cd "$src" && pwd)" != "$root" ] || { echo "하네스 저장소 자체에서는 실행하지 않음"; exit 2; }

git -C "$src" cat-file -e "$base^{commit}" 2>/dev/null || { echo "기준 커밋 ${base}를 하네스 저장소에서 찾을 수 없음"; exit 2; }
base=$(git -C "$src" rev-parse "$base")
new=$(git -C "$src" rev-parse HEAD)
[ "$base" != "$new" ] || { echo "이미 최신 ($new)"; exit 0; }

out=.harness/update
rm -rf "$out"
mkdir -p "$out/seed"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mode_of() {
  git -C "$src" ls-tree "$1" -- "$2" | awk '{print $1}'
}
show() {
  git -C "$src" show "$1:$2" > "$3" 2>/dev/null
}
is_seed() {
  git -C "$src" show "$new:.harness/seed" 2>/dev/null | grep -v '^#' | grep -qx "$1"
}
log() {
  printf '%s\t%s\n' "$1" "$2" >> "$out/list.tsv"
}

{ git -C "$src" ls-tree -r --name-only "$base"; git -C "$src" ls-tree -r --name-only "$new"; } | LC_ALL=C sort -u > "$tmp/paths"

while IFS= read -r p; do
  case "$p" in
    README.md|.harness/version) continue ;;
  esac
  nm=$(mode_of "$new" "$p")
  bm=$(mode_of "$base" "$p")

  if is_seed "$p"; then
    if [ -n "$nm" ] && [ ! -e "$p" ]; then
      mkdir -p "$(dirname "$p")" && show "$new" "$p" "$p" && log 추가 "$p"
    elif [ -n "$nm" ] && [ -n "$bm" ] && ! git -C "$src" diff --quiet "$base" "$new" -- "$p"; then
      d="$out/seed/$(printf '%s' "$p" | tr '/' '_').diff"
      git -C "$src" diff "$base" "$new" -- "$p" > "$d"
      log 템플릿변경 "$p ($d)"
    fi
    continue
  fi

  # 새 버전에서 삭제된 파일: 프로젝트가 고치지 않았을 때만 삭제
  if [ -z "$nm" ]; then
    [ -e "$p" ] || [ -L "$p" ] || continue
    if show "$base" "$p" "$tmp/b" && cmp -s "$p" "$tmp/b"; then
      rm -f "$p" && log 삭제 "$p"
    else
      log 삭제보류 "$p (새 버전에서 삭제됐지만 프로젝트에서 고친 파일)"
    fi
    continue
  fi

  mkdir -p "$(dirname "$p")"
  if [ "$nm" = 120000 ]; then
    target=$(git -C "$src" show "$new:$p")
    if [ "$(readlink "$p" 2>/dev/null)" != "$target" ]; then
      rm -rf "$p" && ln -s "$target" "$p" && log 링크 "$p -> $target"
    fi
    continue
  fi

  show "$new" "$p" "$tmp/n"
  if [ ! -e "$p" ]; then
    cp "$tmp/n" "$p" && log 추가 "$p"
  elif cmp -s "$p" "$tmp/n"; then
    :
  elif [ -n "$bm" ] && show "$base" "$p" "$tmp/b" && cmp -s "$p" "$tmp/b"; then
    cp "$tmp/n" "$p" && log 갱신 "$p"
  else
    [ -n "$bm" ] && show "$base" "$p" "$tmp/b" || : > "$tmp/b"
    git merge-file -p -L 프로젝트 -L "기준 ${base%"${base#???????}"}" -L "새버전 ${new%"${new#???????}"}" "$p" "$tmp/b" "$tmp/n" > "$tmp/m"
    rc=$?
    cp "$tmp/m" "$p"
    if [ "$rc" -eq 0 ]; then log 병합 "$p"; else log 충돌 "$p (${rc}곳)"; fi
  fi
  [ "$nm" = 100755 ] && chmod +x "$p"
done < "$tmp/paths"

printf '%s\n' "$new" > .harness/version

{
  echo "하네스 업데이트: ${base%"${base#???????}"} → ${new%"${new#???????}"}"
  for k in 추가 갱신 병합 충돌 링크 삭제 삭제보류 템플릿변경; do
    n=$(awk -F'\t' -v k="$k" '$1 == k' "$out/list.tsv" 2>/dev/null | grep -c .)
    [ "$n" -gt 0 ] || continue
    echo
    echo "[$k] ${n}건"
    awk -F'\t' -v k="$k" '$1 == k { print "  " $2 }' "$out/list.tsv"
  done
} > "$out/report.txt"
cat "$out/report.txt"

grep -q "^충돌	" "$out/list.tsv" 2>/dev/null && exit 1
exit 0
