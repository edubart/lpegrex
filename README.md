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
**This goal was accomplished, see the Lua example section below.**

The new extensions should not break any existing `re` syntax.

This project will be later incorporated
in the [Nelua](https://github.com/edubart/nelua-lang)
programming language compiler.

## Additional Features

* New predefined patterns for control characters (`%ca` `%cb` `%ct` `%cn` `%cv` `%cf` `%cr`).
* New predefined patterns for utf8 (`%utf8` `%utf8seq` `%ascii`).
* New predefined pattern for spaces independent of locale (`%sp`).
* New syntax for capturing arbitrary values while matching empty strings (e.g. `$true`).
* New syntax for optional captures (e.g `patt~?`).
* New syntax for throwing labels errors on failure of expected matches (e.g. `@rule`).
* New syntax for rules that capture AST Nodes (e.g. `NodeName <== patt`).
* New syntax for rules that capture tables (e.g. `MyList <-| patt`).
* New syntax for matching unique tokens with automatic skipping (e.g. `` `,` ``).
* New syntax for matching unique keywords with automatic skipping (e.g. `` `for` ``).
* Auto generate `KEYWORD` rule based on used keywords in the grammar.
* Auto generate `TOKEN` rule based on used tokens in the grammar.
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
    * `tochar` Substitute a numeric code capture by its corresponding character byte.
    * `toutf8char` Substitute a numeric code capture by its corresponding UTF-8 byte sequence.
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
| Capture token or keyword | `` {`,`} `` | `{','} SKIP` |
| Optional capture | `` patt~? `` | `patt / ''->tofalse` |
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
| `p~?` | `p` captures if it matches, otherwise `false` |

## Capture auxiliary functions

Sometimes is useful to substitute a list of captures by a lua value,
the following tables show auxiliary functions to help on that:

| Purpose | Syntax | Captured Value |
|-|-|-|
| Substitute captures by `nil` | `p -> tonil` | `nil` |
| Substitute captures by `false` | `p -> tofalse` | `false` |
| Substitute captures by `true` | `p -> totrue` | `true` |
| Substitute captures by `{}` | `p -> toemptytable` | `{}` |
| Substitute a capture by a number | `p -> tonumber` | Corresponding number of the captured |
| Substitute a capture by a character byte | `p -> tochar` | Corresponding byte of the captured number |
| Substitute a capture by UTF-8 byte sequence | `p -> toutf8char` | Corresponding UTF-8 bytes of the captured number |

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

In case a **token** is found, the rule `TOKEN` will be automatically generated,
this rule will match any token plus `SKIP`.

In case a **keyword** is found,
the rule `NAME_SUFFIX` also need to be defined, it's used
to differentiate keywords from identifier names.

In most cases the user will need define something like:

```
NAME_SUFFIX   <- [_%w]+
SKIP          <- %s+
```

You may want to edit the `SKIP` rule to consider comments if you grammar supports them.
Token and keywords will not capture `SKIP` rule when using the syntax ``{`keyword`}``.

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

Here is a small example parsing JSON into an AST in 12 lines of PEG rules:

```lua
local lpegrex = require 'lpegrex'

local patt = lpegrex.compile([[
Json          <-- SKIP (Object / Array) (!.)^UnexpectedSyntax
Object        <== `{` (Member (`,` @Member)*)? @`}`
Array         <== `[` (Value (`,` @Value)*)? @`]`
Member        <== String `:` @Value
Value         <-- String / Number / Object / Array / Boolean / Null
String        <-- '"' {~ ('\' -> '' @ESCAPE / !'"' .)* ~} @'"' SKIP
Number        <-- {[+-]? (%d+ '.'? %d+? / '.' %d+) ([eE] [+-]? %d+)?} -> tonumber SKIP
Boolean       <-- `false` -> tofalse / `true` -> totrue
Null          <-- `null` -> tonil
ESCAPE        <-- [\/"] / ('b' $8 / 't' $9 / 'n' $10 / 'f' $12 / 'r' $13 / 'u' {%x^4} $16) -> tochar
SKIP          <-- %s*
NAME_SUFFIX   <-- [_%w]+
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

A JSON parser similar to this example can be found in
[parsers/json.lua](https://github.com/edubart/lpegrex/blob/main/parsers/json.lua).

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

## Complete Lua Example

A Lua 5.4 parser is defined in
[parsers/lua.lua](https://github.com/edubart/lpegrex/blob/main/parsers/lua.lua),
it servers as a good example on how to define a full language grammar
in a single PEG that generates an AST suitable to be analyzed by a compiler,
while also handling source syntax errors.

A Lua AST printer using it is available in
[examples/lua.lua](https://github.com/edubart/lpegrex/blob/main/examples/lua-ast.lua)
You can run it to parse any Lua file and print its AST.

For example by doing `lua examples/lua-ast.lua inputs/fact.lua` you should
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

## Complete C11 example

A complete C11 parser has been implemented and is available in
[parsers/c11.lua](https://github.com/edubart/lpegrex/blob/main/parsers/c11.lua),
it's experimental but it was verified to parse hundreds of prepossessed C file sources.

A C11 AST printer using it is available in
[examples/c11-ast.lua](https://github.com/edubart/lpegrex/blob/main/examples/c11-ast.lua).

Note that the C file must be preprocessed, you can generate a preprocessed C file
with GCC/Clang or running `gcc -E file.c > file_preprocessed.c`.

For example by doing `lua examples/c11-ast.lua inputs/fact.c` you should
get the following AST output:

```
translation-unit
| declaration
| | type-declaration
| | | declaration-specifiers
| | | | storage-class-specifier
| | | | | "extern"
| | | | type-specifier
| | | | | "int"
| | | init-declarator-list
| | | | init-declarator
| | | | | declarator
| | | | | | declarator-parameters
| | | | | | | identifier
| | | | | | | | "printf"
| | | | | | | parameter-type-list
| | | | | | | | parameter-declaration
| | | | | | | | | declaration-specifiers
| | | | | | | | | | type-qualifier
| | | | | | | | | | | "const"
| | | | | | | | | | type-specifier
| | | | | | | | | | | "char"
| | | | | | | | | declarator
| | | | | | | | | | pointer
| | | | | | | | | | | identifier
| | | | | | | | | | | | "format"
| | | | | | | | parameter-varargs
| function-definition
| | declaration-specifiers
| | | storage-class-specifier
| | | | "static"
| | | type-specifier
| | | | "int"
| | declarator
| | | declarator-parameters
| | | | identifier
| | | | | "fact"
| | | | parameter-type-list
| | | | | parameter-declaration
| | | | | | declaration-specifiers
| | | | | | | type-specifier
| | | | | | | | "int"
| | | | | | declarator
| | | | | | | identifier
| | | | | | | | "n"
| | declaration-list
| | compound-statement
| | | if-statement
| | | | expression
| | | | | binary-op
| | | | | | identifier
| | | | | | | "n"
| | | | | | "=="
| | | | | | integer-constant
| | | | | | | "0"
| | | | return-statement
| | | | | expression
| | | | | | integer-constant
| | | | | | | "1"
| | | | return-statement
| | | | | expression
| | | | | | binary-op
| | | | | | | identifier
| | | | | | | | "n"
| | | | | | | "*"
| | | | | | | argument-expression
| | | | | | | | argument-expression-list
| | | | | | | | | binary-op
| | | | | | | | | | identifier
| | | | | | | | | | | "n"
| | | | | | | | | | "-"
| | | | | | | | | | integer-constant
| | | | | | | | | | | "1"
| | | | | | | | identifier
| | | | | | | | | "fact"
| function-definition
| | declaration-specifiers
| | | type-specifier
| | | | "int"
| | declarator
| | | declarator-parameters
| | | | identifier
| | | | | "main"
| | declaration-list
| | compound-statement
| | | expression-statement
| | | | expression
| | | | | argument-expression
| | | | | | argument-expression-list
| | | | | | | string-literal
| | | | | | | | "%d\\n"
| | | | | | | argument-expression
| | | | | | | | argument-expression-list
| | | | | | | | | integer-constant
| | | | | | | | | | "10"
| | | | | | | | identifier
| | | | | | | | | "fact"
| | | | | | identifier
| | | | | | | "printf"
| | | return-statement
| | | | expression
| | | | | integer-constant
| | | | | | "0"
```

## Tests

Most LPeg/LPegLabel tests where migrated into `tests/lpegrex-test.lua`
and new tests for the addition extensions were added.

To run the tests just run `lua tests/test.lua`.

## License

MIT, see LICENSE file.
