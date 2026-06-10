#!/usr/bin/env bash
set -euo pipefail

MODE=""
OUTPUT_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output_path=*)
      OUTPUT_PATH="${1#*=}"
      shift
      ;;
    --output_path)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    base|new)
      MODE="$1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "Usage: $0 <base|new> [--output_path <path>]" >&2
  exit 1
fi

# Rebuild dist/ so tests pick up any patches applied after image build.
pnpm build >/dev/null

# Run test files serially because the repo's vitest.config.ts uses
# `isolate: false`, which makes parallel test files share module state.

# Ensure the output directory exists before vitest tries to write to it.
if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
fi

# Choose reporters based on whether a file output was requested.
# When writing JUnit XML, use only the junit reporter (it also prints
# a summary to stdout).  When running interactively, use the default
# human-readable reporter.
if [[ -n "$OUTPUT_PATH" ]]; then
  ARGS=(
    run
    --reporter=junit
    --outputFile="$OUTPUT_PATH"
    --passWithNoTests
    --no-file-parallelism
  )
else
  ARGS=(
    run
    --reporter=default
    --passWithNoTests
    --no-file-parallelism
  )
fi

case "$MODE" in
  base)
    # Use shell glob so vitest only receives top-level test/*.test.ts files,
    # never descending into test/new/ regardless of vitest version behaviour.
    # Increase testTimeout for Docker environments where child-process recycling
    # tests can exceed the default 5000ms.
    exec pnpm exec vitest "${ARGS[@]}" --testTimeout=30000 --retry=3 test/*.test.ts
    ;;
  new)
    mkdir -p test/new
    exec pnpm exec vitest "${ARGS[@]}" --testTimeout=20000 test/new/*.test.ts
    ;;
esac
