#!/usr/bin/env bash
# Replaces this module's packages with multigres's Postgres parser at a commit, rewriting its import paths.
#
#	./sync.sh [multigres-commit]    # main's HEAD when omitted
#
# Deterministic and idempotent: running it twice at one commit leaves no diff.
set -euo pipefail
repo=$(cd "$(dirname "$0")" && pwd)
commit=${1:-main}
upstream=https://github.com/multigres/multigres.git
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT

git -C "$src" init -q
git -C "$src" remote add origin "$upstream"
git -C "$src" fetch -q --depth 1 origin "$commit"
git -C "$src" checkout -q FETCH_HEAD
sha=$(git -C "$src" rev-parse HEAD)
date=$(git -C "$src" show -s --format=%cs HEAD)

# Everything but this repo's own files is the parser, replaced wholesale
find "$repo" -mindepth 1 -maxdepth 1 \
  ! -name .git ! -name .github ! -name sync.sh ! -name README.md ! -name go.mod ! -name go.sum -exec rm -rf {} +
cp -R "$src/go/common/parser/." "$repo/"
# The generator tool, and the one file that imports pg_query_go (cgo) for speed comparisons
rm -rf "$repo/goyacc" "$repo/parse_benchmark_test.go"
find "$repo" -name '*.go' -exec sed -i 's#github.com/multigres/multigres/go/common/parser#github.com/namiri-tech/pgparser#g' {} +

cp "$src/LICENSE" "$repo/LICENSE"
printf '%s %s\n' "$sha" "$date" >"$repo/UPSTREAM"
cat >"$repo/NOTICE" <<NOTICE
pgparser
Derived from multigres (https://github.com/multigres/multigres, Apache License 2.0) at commit $sha ($date).
Changes: import paths rewritten from github.com/multigres/multigres/go/common/parser to github.com/namiri-tech/pgparser;
goyacc/ and parse_benchmark_test.go removed.
NOTICE

cd "$repo"
go mod tidy
CGO_ENABLED=0 go vet ./...
