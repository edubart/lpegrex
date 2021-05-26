# LPegRex

LPegRex is an re-implementation of
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)/
[LPegLabel](https://github.com/sqmedeiros/lpeglabel)
`re` module with some extensions to make
easy to parse language grammars into an AST (abstract syntax tree)
while maintaining readability.

LPegRex stands for *LPeg Regular Expression eXtended.

## Goals

The goal of this library is to extended the LPeg
[re module](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)
with some minor extensions to make easy parsing a whole
programming language grammar to an abstract syntax tree
using a single, simple, compact and clear PEG grammar.

For instance is in the goal of the project parsing the complete
Lua 5.4 syntax into an abstract syntax tree under 100 lines
of clear PEG grammar with an output suitable to use in compilers.

The new extensions should not break any existing `re` syntax.

If the projects turns out to be successful it will be later
incorporated in the [Nelua](https://github.com/edubart/nelua-lang)
programming language compiler.

## Additional Features

* New predefined patterns for control characters (`%ca` `%cb` `%ct` `%cn` `%cv` `%cf` `%cr`).
* New syntax for capturing arbitrary values while matching empty strings (e.g. `$true`).
* New syntax for throwing labels errors on failure of expected matches (e.g. `@rule`).
* New syntax for rules that capture AST Nodes (e.g. `NodeName <== patt`).
* New syntax for rules that capture tables (e.g. `MyList <-| patt`).
* New syntax for matching unique tokens with automatic skipping (e.g. `` `,` ``).
* New syntax for matching unique keywords with automatic skipping (e.g. `` `for` ``).
* Auto generate `KEYWORD` rule based on used keywords in the grammar.
* Use supplied `NAME_SUFFIX` rule for generating each keyword rule.
* Use supplied `SKIP` rule for generating each keyword or token rule.
* Pre define some useful auxiliary functions:
    * `tonil` Substitute captures by `nil`.
    * `totrue` Substitute captures by `true`.
    * `tofalse` Substitute captures by `false`.
    * `toemptytable` Substitute captures by `{}`.
    * `tonumber` Substitute a string capture by its corresponding number.
    * `tochar` Substitute a numeric code capture by its corresponding UTF-8 character.
    * `foldleft` Fold tables to the left (use only with `~>`).
    * `foldright` Fold tables to the right (use only with `->`).
    * `rfoldleft` Fold tables to the left in reverse order (use only with `->`).
    * `rfoldright` Fold tables to the right in reverse order (use only with `~>`)

## Quick References

For reference on how to use `re` and its syntax, please check [its manual](http://www.inf.puc-rio.br/~roberto/lpeg/re.html) first.

Here is a quick reference of the new syntax additions:

| Purpose | Example Syntax | Equivalent Re Syntax |
|-|-|-|
| Rule | `name <-- patt` | `name <- patt` |
| Capture node rule | `Node <== patt` | `Node <- {\| {:pos:{}:} {:tag:''->'Node':} patt {:endpos:{}:} \|}` |
| Capture tagged node rule | `name : Node <== patt` | `name <- {\| {:pos:{}:} {:tag:''->'Node':} patt {:endpos:{}:} \|}` |
| Capture table rule | `name <-\| patt` | `name <- {\| patt \|}` |
| Match keyword | `` `keyword` `` | `'keyword' !NAME_SUFFIX SKIP` |
| Match token | `` `.` `..` `` | `!('..' SKIP) '.' SKIP '..' SKIP` |
| Match control character | `%cn` | `%nl` |
| Arbitrary capture | `$'string'` | `''->'string'` |
| Expected match | `@'string' @rule` | `'string'^Expected_string rule^Expected_rule` |

As you can notice the added syntax is mostly syntax sugar
for common patterns used when defining programming language grammars.

## Folding auxiliary functions

Here by folding we mean reducing a list of table captures into a single table.
This is useful when generating ASTs because often we need to reduce
a list of AST nodes into a single AST node.
There following table demonstrates the four ways to fold a list of nodes:

| Purpose | Example Input | Corresponding Output | Syntax |
|-|-|-|-|
| Fold tables to the left | `{1}, {2}, {3}` | `{{{1}, 2}, 3}` | `patt ~> foldleft` |
| Fold tables to the right | `{1}, {2}, {3}` | `{1, {2, {3}}}}` | `patt -> foldright` |
| Fold tables to the left in reverse order | `{1}, {2}, {3}` | `{{{3}, 2}, 1}` | `patt -> rfoldleft` |
| Fold tables to the right in reverse order | `{1}, {2}, {3}` | `{{{3}, 2}, 1}` | `patt ~> rfoldright` |

Where the pattern `patt` captures a list of tables with a least one capture.
Note that depending on the fold operation you must use its correct arrow (`->` or `~>`).

## Capture auxiliary syntax

Sometimes is useful to match empty strings and capture some arbitrary values,
the following tables show auxiliary syntax to help on that:

| Syntax | Captured Lua Value |
|-|-|
| `$nil` | `nil` |
| `$true` | `true` |
| `$false` | `false` |
| `$name` | `defs[name]` |
| `${}` | `{}` |
| `$16` | `16` |
| `$'string'` | `"string"` |

## Capture auxiliary functions

Sometimes is we need to substitute a list of captures to a lua value,
the following tables show auxiliary functions to help on that:

| Purpose | Syntax | Captured Lua Value |
|-|-|-|
| Substitute captures by `nil` | `p -> tonil ` | `nil` |
| Substitute captures by `false` | `p -> tofalse ` | `false` |
| Substitute captures by `true` | `p -> tofalse ` | `true` |
| Substitute captures by `{}` | `p -> toemptytable ` | `{}` |
| Substitute a capture by a number | `p -> tonumber ` | Corresponding number of a captured |
| Substitute a capture by an UTF-8 character | `p -> tochar ` | Corresponding string of a captured code |

## User defined rules

When using keywords ot token syntax the user must always define the
`SKIP` and `NAME_SUFFIX` rules. In most cases something like:

```
NAME_SUFFIX   <- [_%w]+
SKIP          <- %s+
```

You may want to edit the `SKIP` rule to consider comments if you grammar supports them.

Often we need to create a rule that capture identifier names while ignoring grammar keywords, let call it `NAME`.
To assist doing this the `KEYWORD` rule is automatically generated based on all defined keywords in
the grammar, the user can then use it to define the `NAME` rule, in most cases something like:

```
NAME          <-- !KEYWORD {NAME_PREFIX NAME_SUFFIX?} SKIP
NAME_PREFIX   <-- [_%a]
NAME_SUFFIX   <-- [_%w]+
SKIP          <- %s+
```

## Usage Example

Here is a small example parsing JSON into an AST in 11 lines of PEG rules:

```lua
local rex = require 'lpegrex'

local json_patt = rex.compile([[
Json          <-- SKIP (Object / Array) (!.)^UnexpectedSyntax
Object        <== `{` (Member (`,` @Member)*)? `}`
Array         <== `[` (Value (`,` @Value)*)? `]`
Member        <== String @`:` @Value
Value         <-- String / Number / Object / Array / Boolean / Null
String        <-- '"' {~ ('\' -> '' @ESCAPE / !'"' .)* ~} '"' SKIP
Number        <-- {[+-]? (%d+ '.'? %d+? / '.' %d+) ([eE] [+-]? %d+)?} -> tonumber SKIP
Boolean       <-- 'false' -> tofalse / 'true' -> totrue
Null          <-- 'null' -> tonil
ESCAPE        <-- [\/"] / ('b' $8 / 't' $9 / 'n' $10 / 'f' $12 / 'r' $13 / 'u' {%x^4} $16) -> tochar
SKIP          <-- %s*
]])

local jsontext = '[{"string":"some\\ntext", "boolean":true, "number":-1.5e+2, "null":null}]'
local json, errlabel, errpos = json_patt:match(jsontext)
assert(json, errlabel)
-- `json` should be a table with the AST
```

The above should parse into the following equivalent AST table:
```lua
{ tag = "Array", pos = 1, endpos = 73,
  { tag = "Object", pos = 2, endpos = 72,
    { tag = "Member", pos = 3, endpos = 24,
    "string","some\ntext" },
    { tag = "Member", pos = 26, endpos = 40,
    "boolean", true },
    { tag = "Member", pos = 42, endpos = 58,
      "number", -150.0 },
    { tag = "Member", pos = 60, endpos = 71,
      "null", nil }
  }
}
```

## Dependencies

To use LPegRex you need [LPegLabel](https://github.com/sqmedeiros/lpeglabel)
to be properly installed.

## Tests

Most LPeg/LPegLabel tests where migrated into `tests/test.lua`
and new tests for the addition extensions were added.

To run the tests just run `lua tests/test.lua`.

## Examples

* Lua 5.4 syntax is defined in
[tests/lua.lua](https://github.com/edubart/lpegrex/blob/main/tests/lua.lua),
it servers as a good example on how to parse a language grammars into an AST from a single PEG.

* A JSON parser is defined in a single PEG in
[tests/json.lua](https://github.com/edubart/lpegrex/blob/main/tests/json.lua).

## License

MIT, see LICENSE file.
