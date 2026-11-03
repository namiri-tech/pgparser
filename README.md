# pgparser

A pure-Go PostgreSQL parser, published as its own module. It is
[multigres](https://github.com/multigres/multigres)'s `go/common/parser`, a goyacc port of Postgres's grammar by the
Supabase and Vitess team, with its import paths rewritten so it can be required without the whole multigres module.
No cgo.

```sh
go get github.com/namiri-tech/pgparser@latest
```

The package keeps upstream's name, `parser`:

```go
import "github.com/namiri-tech/pgparser"

stmts, err := parser.ParseSQL("SELECT id FROM sale WHERE total_amount > 100")
```

## How it tracks upstream

`sync.sh [commit]` replaces the packages with multigres's parser at a commit (main's HEAD by default), rewrites the
import paths, drops the `goyacc` generator and the one benchmark that imports `pg_query_go` (cgo), and records the
commit in `UPSTREAM` and `NOTICE`. It is deterministic: a second run at the same commit changes nothing.

A weekly workflow runs it against multigres `main` and opens a pull request when anything changed. CI runs the upstream
test suite, including the Postgres regression statements in `testdata/`, with `CGO_ENABLED=0`. After merging a sync
pull request, tag the next minor version (`v0.N.0`); fixes of our own take a patch version.

`postgres.go` is generated upstream from `postgres.y` and checked in, so the `go:generate` lines, which point at
multigres's tools, aren't run here.

## Licence

Apache License 2.0, as upstream; see `LICENSE` and `NOTICE`. If multigres ever publishes the parser as a module of its
own, consumers should switch to it and this repository should be archived.
