# tree-sitter-postgres grammar repo to sync query files from.
grammar_repo := "https://github.com/gmr/tree-sitter-postgres"

_default:
    @just --list

# Re-copy the bundled query files from tree-sitter-postgres at the commit
# pinned in extension.toml. Zed reads queries from this extension's
# languages/<name>/ directories, not from the grammar repo, so they must be
# re-copied whenever the pinned grammar `rev` changes.
sync-queries:
    #!/usr/bin/env bash
    set -euo pipefail
    commit="$(grep -m1 '^rev' extension.toml | sed -E 's/.*"([0-9a-f]+)".*/\1/')"
    if [[ -z "$commit" ]]; then
      echo "error: could not read pinned rev from extension.toml" >&2
      exit 1
    fi
    echo "Syncing queries from {{grammar_repo}} @ $commit"
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT
    git -C "$workdir" init -q
    git -C "$workdir" remote add origin "{{grammar_repo}}"
    git -C "$workdir" fetch -q --depth 1 origin "$commit"
    git -C "$workdir" checkout -q FETCH_HEAD
    copy() {
      local src="$workdir/$1" dst="$2"
      if [[ ! -f "$src" ]]; then
        echo "error: missing query file in grammar: $1" >&2
        exit 1
      fi
      cp "$src" "$dst"
      echo "  $1 -> $dst"
    }
    copy postgres/queries/highlights.scm  languages/postgres/highlights.scm
    copy postgres/queries/injections.scm  languages/postgres/injections.scm
    copy postgres/queries/outline.scm     languages/postgres/outline.scm
    copy plpgsql/queries/highlights.scm   languages/plpgsql/highlights.scm
    copy plpgsql/queries/injections.scm   languages/plpgsql/injections.scm
    echo "Done. Review 'git diff' and commit the result."

# Verify the manifest, language configs, and that bundled queries are in sync
# with the pinned grammar commit. Mirrors what CI checks.
check:
    #!/usr/bin/env bash
    set -euo pipefail
    python3 - <<'PY'
    import tomllib, pathlib
    ext = tomllib.loads(pathlib.Path("extension.toml").read_text())
    for key in ("id", "name", "version", "schema_version"):
        assert key in ext, f"extension.toml missing required key: {key}"
    assert ext["grammars"], "extension.toml declares no grammars"
    for name in ext["grammars"]:
        d = pathlib.Path("languages") / name
        assert (d / "config.toml").is_file(), f"missing languages/{name}/config.toml"
        assert (d / "highlights.scm").is_file(), f"missing languages/{name}/highlights.scm"
        cfg = tomllib.loads((d / "config.toml").read_text())
        assert cfg.get("grammar") in ext["grammars"], \
            f"languages/{name}/config.toml grammar not declared in extension.toml"
    print("manifest and language configs OK")
    PY
    just sync-queries
    if ! git diff --exit-code -- languages; then
      echo "error: bundled queries are out of sync; commit the result of 'just sync-queries'" >&2
      exit 1
    fi
