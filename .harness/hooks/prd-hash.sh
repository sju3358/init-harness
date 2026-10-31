#!/bin/sh
# 현재 요구사항·PRD·API 문서 해시 출력(읽기 전용). PRD 검증 회차 머리의 "- 문서 해시:" 줄에 적는다
# `PRD 승인`은 마지막 전체 검증 회차의 이 값이 현재 문서 해시와 같을 때만 기록됨 (record-approval.sh)
# 사용법: sh .harness/hooks/prd-hash.sh

dir=$(dirname "$0")
. "$dir/lib.sh"

hash=$(prd_hash)
[ -n "$hash" ] || { echo "해시 도구(shasum·sha256sum)를 찾지 못함" >&2; exit 1; }
echo "$hash"
