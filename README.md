# LPegRex

LPegRex is an re-implementation of [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)/[LPegLabel](https://github.com/sqmedeiros/lpeglabel)
`re` module with some extensions to make
easy to parse language grammars into an AST (abstract syntax tree)
while maintaining readability.

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

* New syntax for capturing arbitrary values on empty strings (e.g. `$true`)
* New syntax for throwing labels errors on failure of expected matches (e.g. `@rule`).
* New syntax for matching tokens with automatic skipping (e.g. `` `,` ``).
* New syntax for matching keywords with automatic skipping (e.g. `` `function` ``).
* New syntax for rules that capture AST Nodes (e.g. `NodeName <== patt`).
* New syntax for rules that capture tables (e.g. `MyList <-| patt`).
* Alternative syntax from common rules (e.g. `rule <-- patt`).
* Pre defined auxiliary functions:
    * `tonumber` Substitute a numeric capture by a number.
    * `tochar` Substitute a numeric capture by an UTF-8 character.
    * `totrue` Substitute captures by `true`.
    * `tofalse` Substitute captures by `false`.
    * `tonil` Substitute captures by `nil`.
    * `rfold` Fold table captures to the right.

## Planned features

* Builtin utilities for folding AST nodes.
* Builtin but overridable `SKIP`, `NAME_PREFIX`, `NAME_SUFFIX` rules.
* Builtin automatic generated `NAME` and `KEYWORD` rules.
* Generated token and keyword rules automatically.

## Tests

Most LPeg/LPegLabel tests where migrated into `tests/test.lua`
and new tests for the addition extensions were added.

To run the tests just run `lua tests/test.lua`.

## License

MIT, see LICENSE file.
