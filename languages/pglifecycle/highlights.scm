; Highlighting for pglifecycle YAML (tree-sitter-yaml grammar).
; SQL-bearing fields get their highlighting via language injection; see
; injections.scm.

(comment) @comment

(boolean_scalar) @boolean
(null_scalar) @constant.builtin
[
  (integer_scalar)
  (float_scalar)
] @number

[
  (double_quote_scalar)
  (single_quote_scalar)
  (block_scalar)
  (string_scalar)
] @string

(escape_sequence) @string.escape

[
  (anchor_name)
  (alias_name)
  (tag)
] @type

; Mapping keys
key: (flow_node
  [
    (plain_scalar (string_scalar))
    (double_quote_scalar)
    (single_quote_scalar)
  ] @property)

[
  ","
  "-"
  ":"
  ">"
  "?"
  "|"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "*"
  "&"
  "---"
  "..."
] @punctuation.special
