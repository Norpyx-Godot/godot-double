#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COVERAGE_DIR="${COVERAGE_DIR:-$ROOT_DIR/coverage}"
LINE_THRESHOLD="${LINE_COVERAGE_THRESHOLD:-80}"
TRACE_FILE="$COVERAGE_DIR/bash-xtrace.log"
EXECUTED_FILE="$COVERAGE_DIR/executed-lines.txt"
SUMMARY_FILE="$COVERAGE_DIR/summary.txt"

COVERAGE_FILES=(
  scripts/arch-latest.sh
  scripts/update.sh
  scripts/sync-arch-pkgbuild.sh
  scripts/preflight.sh
  scripts/bump-check.sh
  scripts/metadata-check.sh
  scripts/stage.sh
  scripts/validate.sh
  scripts/docker.sh
  scripts/ci.sh
  scripts/test.sh
  scripts/source-check.sh
  scripts/artifact-check.sh
  scripts/hydrate-check.sh
)

count_code_lines() {
  awk '
    BEGIN { in_heredoc = 0 }
    in_heredoc {
      if ($0 == heredoc_end) {
        in_heredoc = 0
      }
      next
    }
    {
      line = $0
      if (line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/) {
        next
      }
      if (line ~ /<<'\''?[A-Za-z_][A-Za-z0-9_]*'\''?/) {
        heredoc_end = line
        sub(/^.*<</, "", heredoc_end)
        gsub(/'\''/, "", heredoc_end)
        sub(/[[:space:]].*$/, "", heredoc_end)
        in_heredoc = 1
        count++
        next
      }
      if (line ~ /^[[:space:]]*[A-Za-z0-9_]+\(\)[[:space:]]*\{[[:space:]]*$/) {
        next
      }
      if (line ~ /^[[:space:]]*(\{|\}|;;|case .* in|esac|then|else|fi|do|done)[[:space:]]*$/) {
        next
      }
      count++
    }
    END { print count + 0 }
  ' "$1"
}

count_covered_lines() {
  local file="$1"

  awk -F: -v file="$file" '
    $1 == file { covered[$2] = 1 }
    END {
      for (line in covered) {
        count++
      }
      print count + 0
    }
  ' "$EXECUTED_FILE"
}

rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

(
  exec 9>"$TRACE_FILE"
  export BASH_XTRACEFD=9
  export PS4='+${BASH_SOURCE[0]-$0}:${LINENO}: '
  export SHELLOPTS
  bash -x "$ROOT_DIR/tests/run.sh"
)

awk -v root="$ROOT_DIR" '
  /^\++.*:[0-9]+:/ {
    line = $0
    sub(/^\++/, "", line)
    split(line, parts, ":")
    file = parts[1]
    line_no = parts[2]
    if (index(file, root "/bin/") == 1 || index(file, root "/scripts/") == 1) {
      print file ":" line_no
    }
  }
' "$TRACE_FILE" | sort -u > "$EXECUTED_FILE"

total_lines=0
covered_lines=0

: > "$SUMMARY_FILE"
for relative_file in "${COVERAGE_FILES[@]}"; do
  absolute_file="$ROOT_DIR/$relative_file"
  file_total="$(count_code_lines "$absolute_file")"
  file_covered="$(count_covered_lines "$absolute_file")"
  total_lines=$((total_lines + file_total))
  covered_lines=$((covered_lines + file_covered))

  awk -v file="$relative_file" -v covered="$file_covered" -v total="$file_total" '
    BEGIN {
      percent = total ? (covered * 100 / total) : 100
      printf "%s %d/%d %.1f%%\n", file, covered, total, percent
    }
  ' | tee -a "$SUMMARY_FILE"
done

line_percent="$(
  awk -v covered="$covered_lines" -v total="$total_lines" 'BEGIN { printf "%.1f", total ? (covered * 100 / total) : 100 }'
)"

printf 'line_coverage %d/%d %s%%\n' "$covered_lines" "$total_lines" "$line_percent" | tee -a "$SUMMARY_FILE"
printf 'branch_coverage not-measured\n' | tee -a "$SUMMARY_FILE"

if ! awk -v actual="$line_percent" -v expected="$LINE_THRESHOLD" 'BEGIN { exit !(actual + 0 >= expected + 0) }'; then
  printf 'error: line coverage %s%% is below required %s%%\n' "$line_percent" "$LINE_THRESHOLD" >&2
  exit 1
fi
