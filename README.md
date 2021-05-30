# LPegRex

LPegRex is an re-implementation of
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)/
[LPegLabel](https://github.com/sqmedeiros/lpeglabel)
`re` module with some extensions to make
easy to parse language grammars into an AST (abstract syntax tree)
while maintaining readability.

LPegRex stands for *LPeg Regular Expression eXtended*.

## Goals

The goal of this library is to extended the LPeg
[re module](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)
with some minor additions to make easy parsing a whole
programming language grammar to an abstract syntax tree
using a single, simple, compact and clear PEG grammar.

For instance is in the goal of the project to parse Lua 5.4 source
files with complete syntax into an abstract syntax tree under 100 lines
of clear PEG grammar rules while generating an output suitable to be used analyzed by a compiler.
**This goal was accomplished and it's in the tests folder.**

The new extensions should not break any existing `re` syntax.

This project will be later incorporated
in the [Nelua](https://github.com/edubart/nelua-lang)
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
* Capture nodes with initial and final positions.
* Support using `-` character in rule names.
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

For reference on how to use `re` and its syntax,
please check [its manual](http://www.inf.puc-rio.br/~roberto/lpeg/re.html) first.

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

As you can notice the additional syntax is mostly sugar
for common capture patterns that are used when defining programming language grammars.

## Folding auxiliary functions

Often we need to reduce a list of captured AST nodes into a single captured AST node
(e.g. when reducing a call chain),
here we call this operation folding.
The following table demonstrates the four ways to fold a list of nodes:

| Purpose | Example Input | Corresponding Output | Syntax |
|-|-|-|-|
| Fold tables to the left | `{1}, {2}, {3}` | `{{{1}, 2}, 3}` | `patt ~> foldleft` |
| Fold tables to the right | `{1}, {2}, {3}` | `{1, {2, {3}}}}` | `patt -> foldright` |
| Fold tables to the left in reverse order | `{1}, {2}, {3}` | `{{{3}, 2}, 1}` | `patt -> rfoldleft` |
| Fold tables to the right in reverse order | `{1}, {2}, {3}` | `{3, {2, {1}}` | `patt ~> rfoldright` |

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

Sometimes is useful to substitute a list of captures by a lua value,
the following tables show auxiliary functions to help on that:

| Purpose | Syntax | Captured Lua Value |
|-|-|-|
| Substitute captures by `nil` | `p -> tonil ` | `nil` |
| Substitute captures by `false` | `p -> tofalse ` | `false` |
| Substitute captures by `true` | `p -> totrue ` | `true` |
| Substitute captures by `{}` | `p -> toemptytable ` | `{}` |
| Substitute a capture by a number | `p -> tonumber ` | Corresponding number of the captured |
| Substitute a capture by an UTF-8 character | `p -> tochar ` | Corresponding string of the captured code |

## Captured node fields

By default when capturing a node with `<==` syntax, LPegRex will set the following 3 fields:

* `tag` Name of the node (its type)
* `pos` Initial position of the node match
* `endpos` Final position of the node match (usually includes following SKIP)

The user can customize and change these field names or disable them by
setting it's corresponding name in the `defs.__options` table when compiling the grammar,
for example:

```lua
local mypatt = rex.compile(mygrammar, {__options = {
  tag = 'name', -- 'tag' field rename to 'name'
  pos = 'init', -- 'pos' field renamed to 'init'
  endpos = false, -- don't capture node final position
}})
```

The fields `pos` and `endpos` are useful to generate error messages with precise location
when analyzing the AST and the `tag` field is used to distinguish the node type.

## Captured node action

In case `defs.__options.tag` is a function, then it's called and the user will be responsible for
setting the tag field and return the node, this flexibility exists in case
specific actions are required to be executed on node creation, for example:

```lua
local mypatt = rex.compile(mygrammar, {__options = {
  tag = function(tag, node)
    print('new node', tag)
    node.tag = tag
    return node
  end
}})
```

Note that when this function is called the node children may be incomplete
in case the node is being folded.

## Matching keywords and tokens

When using the back tick syntax (e.g. `` `something` ``),
LPegRex will register its contents as a **keyword** in case it begins with a letter (or `_`),
or as **token** in case it contains only punctuation characters (except `_`).

Both keywords and tokens always match the `SKIP` rule immediately to
skip spaces, thus the rule `SKIP` must always be defined when using the back tick syntax.

Tokens matches are always unique in case of common characters, that is,
in case both `.` and `..` tokens are defined, the rule `` `.` `` will match
`.` but not `..`.

In case of a **keyword** is found,
the rule `NAME_SUFFIX` also need to be defined, it's used
to differentiate keywords from identifier names.

In most cases the user will need define something like:

```
NAME_SUFFIX   <- [_%w]+
SKIP          <- %s+
```

You may want to edit the `SKIP` rule to consider comments if you grammar supports them.

## Capturing identifier names

Often we need to create a rule that capture identifier names while ignoring grammar keywords, let call this rule `NAME`.
To assist doing this the `KEYWORD` rule is automatically generated based on all defined keywords in
the grammar, the user can then use it to define the `NAME` rule, in most cases something like:

```
NAME          <-- !KEYWORD {NAME_PREFIX NAME_SUFFIX?} SKIP
NAME_PREFIX   <-- [_%a]
NAME_SUFFIX   <-- [_%w]+
SKIP          <- %s+
```

## Handling syntax errors

Any rule name, keyword, token or string pattern can be preceded by the token `@`,
marking it as an expected match, in case the match is not fulfilled an error
label will be thrown using the name `Expected_name`, where `name` is the
token, keyword or rule name.

Once an error label is found, the user can generate pretty syntax error
messages using the function `lpegrex.calcline` to gather line information,
for example:

```lua
local patt = lpegrex.compile(PEG)
local ast, errlabel, errpos = patt:match(source)
if not ast then
  local lineno, colno, line = lpegrex.calcline(source, errpos)
  local colhelp = string.rep(' ', colno-1)..'^'
  error('syntax error: '..filename..':'..lineno..':'..colno..': '..errlabel..
        '\n'..line..'\n'..colhelp)
end
```

## Usage Example

Here is a small example parsing JSON into an AST in 11 lines of PEG rules:

```lua
local lpegrex = require 'lpegrex'

local patt = lpegrex.compile([[
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

local source = '[{"string":"some\\ntext", "boolean":true, "number":-1.5e+2, "null":null}]'

local ast, errlabel, errpos = patt:match(source)
if not ast then
  local lineno, colno, line = lpegrex.calcline(source, errpos)
  local colhelp = string.rep(' ', colno-1)..'^'
  error('syntax error: '..lineno..':'..colno..': '..errlabel..
        '\n'..line..'\n'..colhelp)
end
-- `ast` should be a table with the JSON
print('JSON parsed with success!')
```

The above should parse into the following equivalent AST table:
```lua
local ast = { tag = "Array", pos = 1, endpos = 73,
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

This example can be found in
[tests/json.lua](https://github.com/edubart/lpegrex/blob/main/tests/json.lua).

## Complete Example

A Lua 5.4 parser is defined in
[tests/lua.lua](https://github.com/edubart/lpegrex/blob/main/tests/lua.lua),
it servers as a good example on how to define a full language grammar
in a single PEG that generates an AST suitable to be analyzed by a compiler,
while also handling source syntax errors.
You can run it to parse any Lua file and print its AST.

For example by doing `lua tests/lua.lua tests/fact.lua` you should
get the following AST output:

```
Block
| FuncDecl
| | Id
| | | "fact"
| | -
| | | Id
| | | | "n"
| | Block
| | | If
| | | | BinaryOp
| | | | | Id
| | | | | | "n"
| | | | | "eq"
| | | | | Number
| | | | | | 0
| | | | Block
| | | | | Return
| | | | | | -
| | | | | | | Number
| | | | | | | | 1
| | | | Block
| | | | | Return
| | | | | | -
| | | | | | | BinaryOp
| | | | | | | | Id
| | | | | | | | | "n"
| | | | | | | | "mul"
| | | | | | | | Call
| | | | | | | | | -
| | | | | | | | | | BinaryOp
| | | | | | | | | | | Id
| | | | | | | | | | | | "n"
| | | | | | | | | | | "sub"
| | | | | | | | | | | Number
| | | | | | | | | | | | 1
| | | | | | | | | Id
| | | | | | | | | | "fact"
| Call
| | -
| | | Call
| | | | -
| | | | | Number
| | | | | | 10
| | | | Id
| | | | | "fact"
| | Id
| | | "print"
```

## Installing

To use LPegRex you need [LPegLabel](https://github.com/sqmedeiros/lpeglabel)
to be properly installed.
If you have it already installed you can just copy the
[lpegrex.lua](https://github.com/edubart/lpegrex/blob/main/lpegrex.lua) file.

If you can also install it using the
[LuaRocks](https://luarocks.org/) package manager,
with the following command:

```shell
luarocks install lpegrex
```

The library should work with Lua 5.x versions (and also LuaJIT).

## Tests

Most LPeg/LPegLabel tests where migrated into `tests/test.lua`
and new tests for the addition extensions were added.

To run the tests just run `lua tests/test.lua`.

## License

MIT, see LICENSE file.
