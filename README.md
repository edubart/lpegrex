# LPegRex

LPegRex is an re-implementation of
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)/
[LPegLabel](https://github.com/sqmedeiros/lpeglabel)
`re` module with some extensions to make
easy to parse language grammars into an AST (abstract syntax tree)
while maintaining readability.

LPegRex stands for *LPeg Regular Expression eXtended.

**NOTE:** This is currently under research, development and incomplete.

## Goals

The goal of this library is to extended the LPeg
[re module](http://www.inf.puc-rio.br/~roberto/lpeg/re.html)
with some minor extensions to make easy parsing a whole
programming language grammar to an abstract syntax tree
using a single, simple, compact and clear PEG grammar.

For instance is in the goal of the project parsing the complete
Lua 5.4 syntax into an abstract syntax tree under 100 lines
of clear PEG grammar, suitable for use in compilers.

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
    * `tonumber` Substitute a string capture by its corresponding number.
    * `tochar` Substitute a numeric code capture by its corresponding UTF-8 character.
    * `foldleft` Fold tables to the left (use only with `~>`).
    * `foldright` Fold tables to the right (use only with `->`).
    * `rfoldleft` Fold tables to the left in reverse order (use only with `->`).
    * `rfoldright` Fold tables to the right in reverse order (use only with `~>`)

## Tests

Most LPeg/LPegLabel tests where migrated into `tests/test.lua`
and new tests for the addition extensions were added.

To run the tests just run `lua tests/test.lua`.

## License

MIT, see LICENSE file.
