; Inject PostgreSQL / PL/pgSQL highlighting into the SQL-bearing fields of
; pglifecycle project YAML.
;
; Injection language names resolve against Zed language *names* (case-insensitive)
; or path_suffixes — not grammar names — so we target "PostgreSQL" and "PL/pgSQL"
; (the names declared in languages/{postgres,plpgsql}/config.toml).

; ── Comments (so the modeline reads as a comment) ───────────────────────────
((comment) @injection.content
  (#set! injection.language "comment"))

; ── Unconditional PostgreSQL fields ─────────────────────────────────────────
; Keys whose value is always plain Postgres SQL regardless of context: the raw
; `sql` escape hatch, view/matview `query`, index/column `expression`, partial
; index `where`, trigger `when`, check `check`, and column `default`.
((block_mapping_pair
   key: (flow_node) @_key
   value: [
     (flow_node (plain_scalar (string_scalar) @injection.content))
     (flow_node (single_quote_scalar) @injection.content)
     (flow_node (double_quote_scalar) @injection.content)
     (block_node (block_scalar) @injection.content)
   ])
  (#match? @_key "^(sql|query|expression|where|when|check|default)$")
  (#set! injection.language "PostgreSQL"))

; ── Function / aggregate body: language drives the injected language ────────
; A function file has sibling `language:` and `definition:` keys in the same
; mapping. pglifecycle emits `language` before `definition`; both orderings are
; matched here for robustness against hand-authored files. Languages other than
; sql/plpgsql (plpython3u, plperl, c) are intentionally left un-injected.

; language: sql  ->  PostgreSQL
(block_mapping
  (block_mapping_pair
    key: (flow_node) @_lk
    value: (flow_node) @_lv)
  (block_mapping_pair
    key: (flow_node) @_dk
    value: (block_node (block_scalar) @injection.content))
  (#eq? @_lk "language") (#eq? @_lv "sql")
  (#eq? @_dk "definition")
  (#set! injection.language "PostgreSQL"))

(block_mapping
  (block_mapping_pair
    key: (flow_node) @_dk
    value: (block_node (block_scalar) @injection.content))
  (block_mapping_pair
    key: (flow_node) @_lk
    value: (flow_node) @_lv)
  (#eq? @_dk "definition")
  (#eq? @_lk "language") (#eq? @_lv "sql")
  (#set! injection.language "PostgreSQL"))

; language: plpgsql  ->  PL/pgSQL
(block_mapping
  (block_mapping_pair
    key: (flow_node) @_lk
    value: (flow_node) @_lv)
  (block_mapping_pair
    key: (flow_node) @_dk
    value: (block_node (block_scalar) @injection.content))
  (#eq? @_lk "language") (#eq? @_lv "plpgsql")
  (#eq? @_dk "definition")
  (#set! injection.language "PL/pgSQL"))

(block_mapping
  (block_mapping_pair
    key: (flow_node) @_dk
    value: (block_node (block_scalar) @injection.content))
  (block_mapping_pair
    key: (flow_node) @_lk
    value: (flow_node) @_lv)
  (#eq? @_dk "definition")
  (#eq? @_lk "language") (#eq? @_lv "plpgsql")
  (#set! injection.language "PL/pgSQL"))
