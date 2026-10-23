#!/bin/sh
# PRD 승인 유효 여부 확인. 승인 시점 해시와 현재 요구사항·PRD 해시가 같으면 exit 0
# 사용법: sh .harness/hooks/prd-check.sh

dir=$(dirname "$0")
. "$dir/lib.sh"

f="$(state_dir)/prd-approved"
if [ ! -f "$f" ]; then
  echo "PRD 승인 기록 없음. Claude에서 prd-verify 후 'PRD 승인'을 받아야 함"
  exit 1
fi
if [ "$(cat "$f")" != "$(prd_hash)" ]; then
  echo "PRD 승인 이후 docs/requirements.md, docs/prd/, docs/api/ 내용이 바뀜. Claude에서 재검증 후 'PRD 승인'을 다시 받아야 함"
  exit 1
fi
echo "PRD 승인 유효"
