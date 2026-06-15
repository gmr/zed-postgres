# zed-postgres

A [Zed](https://zed.dev) extension providing PostgreSQL and PL/pgSQL syntax
highlighting, code outlines, and SQL injection support, powered by
[`tree-sitter-postgres`](https://github.com/gmr/tree-sitter-postgres) — a
PostgreSQL grammar generated directly from PostgreSQL's own Bison grammar. It
also highlights the SQL and PL/pgSQL embedded in
[`pglifecycle`](https://github.com/gmr/pglifecycle) project YAML files.

## What you get

| Language     | Scope        | File types            | Source grammar |
| ------------ | ------------ | --------------------- | -------------- |
| PostgreSQL   | `source.sql` | `.sql`, `.psql`, `.pgsql` | `postgres` |
| PL/pgSQL     | —            | (via injection)       | `plpgsql`      |
| pglifecycle  | —            | YAML via modeline (see below) | `yaml`  |

PL/pgSQL has no canonical file extension; it is highlighted primarily through
injection into function bodies (`CREATE FUNCTION ... $$ ... $$`), where the
dollar-quoted body is parsed by the `postgres` grammar.

### pglifecycle YAML support

pglifecycle projects are directories of plain `.yaml`/`.yml` files. To avoid
hijacking *every* YAML file, this extension does **not** claim the `.yaml`/`.yml`
extensions. Instead it activates only when a file carries an editor modeline
naming the `pglifecycle` language on its first line:

```yaml
# -*- mode: pglifecycle -*-
---
schema: test
name: disable_alter_domain()
language: plpgsql
definition: |
  BEGIN
    RAISE EXCEPTION 'nope';
  END;
```

Zed parses the modeline (within the first `modeline_lines`, default 5) and
selects the `pglifecycle` language, overriding the default YAML detection. The
extension then injects:

- **PostgreSQL** into the always-SQL fields: `sql`, `query`, `expression`,
  `where`, `when`, `check`, `default`.
- **PostgreSQL** or **PL/pgSQL** into a function/aggregate `definition`, chosen
  by the sibling `language:` value (`sql` → PostgreSQL, `plpgsql` → PL/pgSQL).
  Other languages (`plpython3u`, `plperl`, `c`) are left un-injected.

pglifecycle emits the modeline automatically; see its docs for the convention.
Sample files live in [`examples/pglifecycle/`](examples/pglifecycle).

## Layout

```
extension.toml                 # extension manifest; pins all three grammar commits
languages/
  postgres/                    # SQL — synced from tree-sitter-postgres
    config.toml                # name, grammar, path_suffixes, brackets
    highlights.scm
    injections.scm
    outline.scm
  plpgsql/                     # PL/pgSQL — synced from tree-sitter-postgres
    config.toml
    highlights.scm
    injections.scm
  pglifecycle/                 # YAML + pglifecycle injections — hand-authored
    config.toml                # grammar = yaml, modeline_aliases, no path_suffixes
    highlights.scm
    injections.scm
examples/pglifecycle/          # sample files for manual verification
justfile                       # sync-queries / check recipes (see below)
```

The `postgres`/`plpgsql` `.scm` files are copies of the grammar's queries at the
commit pinned in `extension.toml`, kept in sync by `just sync-queries`. The
`pglifecycle` queries are hand-authored and not synced (they target the YAML
grammar, not tree-sitter-postgres). Zed reads queries from these
`languages/<name>/` directories, not from the grammar repos.

## Install locally (dev extension)

1. Open Zed's command palette (`cmd-shift-p`).
2. Run **`zed: install dev extension`**.
3. Select this repository's directory.

Zed fetches and compiles the grammars on first install. Open a `.sql` file to
verify highlighting, and use **`editor: toggle syntax tree view`** to inspect the
parse output.

## Maintenance — bumping the grammar

1. Find the commit SHA of the grammar tag you want:

   ```bash
   git ls-remote https://github.com/gmr/tree-sitter-postgres refs/tags/vX.Y.Z
   ```

2. Update the `commit` value for **both** `[grammars.postgres]` and
   `[grammars.plpgsql]` in `extension.toml`.
3. Re-copy the query files so they match the new grammar:

   ```bash
   just sync-queries
   ```

4. Bump `version` in `extension.toml`.
5. Run `just check`, then `git diff` to confirm only intended changes landed.

CI runs `just check` and fails the build if the bundled queries drift from the
pinned commit, so this step cannot be silently skipped.

## Publishing

Zed extensions are published by opening a pull request against
[`zed-industries/extensions`](https://github.com/zed-industries/extensions).
The `Publish` workflow automates that PR when a `v*` tag is pushed.

One-time setup:

1. The fork of `zed-industries/extensions` is `gmr/zed-extensions`, already set
   as `push-to` in `.github/workflows/publish.yml`.
2. Create a repository secret `ZED_EXTENSION_PUBLISH_TOKEN` — a personal access
   token with `repo` and `workflow` scopes that can push to the fork.

To cut a release:

```bash
# extension.toml version must already equal X.Y.Z
git tag vX.Y.Z
git push origin vX.Y.Z
```

The workflow verifies the tag matches `extension.toml`, confirms the queries are
in sync, then opens the upstream PR.

## References

- tree-sitter-postgres: <https://github.com/gmr/tree-sitter-postgres>
- Zed — developing extensions: <https://zed.dev/docs/extensions/developing-extensions>
- Zed — language extensions: <https://zed.dev/docs/extensions/languages>
