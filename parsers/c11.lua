--[[
This grammar is based on the C11 specification.
As seen in https://port70.net/~nsz/c/c11/n1570.html#A.1
Support for parsing some new C2x syntax were also added.
Support for some extensions to use with GCC/Clang were also added.
]]
local Grammar = [==[
chunk <- SHEBANG? SKIP translation-unit (!.)^UnexpectedSyntax

SHEBANG       <-- '#!' (!LINEBREAK .)* LINEBREAK?

COMMENT       <-- LONG_COMMENT / SHRT_COMMENT
LONG_COMMENT  <-- '/*' (!'*/' .)* '*/'
SHRT_COMMENT  <-- '//' (!LINEBREAK .)* LINEBREAK?
DIRECTIVE     <-- '#' ('\' LINEBREAK / !LINEBREAK .)*

SKIP          <-- (%s+ / COMMENT / DIRECTIVE / `__extension__`)*
LINEBREAK     <-- %nl %cr / %cr %nl / %nl / %cr

NAME_SUFFIX   <-- identifier-suffix

--------------------------------------------------------------------------------
-- Identifiers

identifier <== identifier-word

identifier-word <--
  !KEYWORD identifier-anyword

identifier-anyword <--
  {identifier-nondigit identifier-suffix?} SKIP

free-identifier:identifier <==
  identifier-word

identifier-suffix <- (identifier-nondigit / digit)+
identifier-nondigit <- [a-zA-Z_] / universal-character-name

digit <- [0-9]

--------------------------------------------------------------------------------
-- Universal character names

universal-character-name <--
 '\u' hex-quad /
 '\U' hex-quad^2
hex-quad <-- hexadecimal-digit^4

--------------------------------------------------------------------------------
-- Constants

constant <-- (
    floating-constant /
    integer-constant /
    enumeration-constant /
    character-constant
  ) SKIP

integer-constant <==
  {octal-constant integer-suffix?} /
  {hexadecimal-constant integer-suffix?} /
  {decimal-constant integer-suffix?}

decimal-constant <-- digit+
octal-constant <-- '0' octal-digit+
hexadecimal-constant <-- hexadecimal-prefix hexadecimal-digit+
hexadecimal-prefix <-- '0' [xX]
octal-digit <--  [0-7]
hexadecimal-digit <-- [0-9a-fA-F]

integer-suffix <--
  unsigned-suffix (long-suffix long-suffix?)? /
  (long-suffix long-suffix?) unsigned-suffix?

unsigned-suffix <-- [uU]
long-suffix <-- [lL]

floating-constant <==
  {decimal-floating-constant} /
  {hexadecimal-floating-constant}

decimal-floating-constant <--
  (
    fractional-constant exponent-part? /
    digit-sequence exponent-part
  ) floating-suffix?

hexadecimal-floating-constant <--
 hexadecimal-prefix
 (hexadecimal-fractional-constant / hexadecimal-digit-sequence)
 binary-exponent-part floating-suffix?

fractional-constant <--
  digit-sequence? '.' digit-sequence /
  digit-sequence '.'

exponent-part <--[eE] sign? digit-sequence
sign <-- [+-]
digit-sequence <-- digit+

hexadecimal-fractional-constant <--
 hexadecimal-digit-sequence? '.' hexadecimal-digit-sequence /
 hexadecimal-digit-sequence '.'

binary-exponent-part <-- [pP] sign? digit-sequence
hexadecimal-digit-sequence <-- hexadecimal-digit+
floating-suffix <-- [fFlLqQ]

enumeration-constant <--
  identifier

character-constant <==
 [LUu]? "'" {~c-char-sequence~} "'"

c-char-sequence <-- c-char+
c-char <--
  [^'\%cn%cr] /
  escape-sequence

escape-sequence <--
 simple-escape-sequence /
 octal-escape-sequence /
 hexadecimal-escape-sequence /
 universal-character-name

simple-escape-sequence <--
 "\"->'' simple-escape-sequence-suffix

simple-escape-sequence-suffix <-
  [\'"?] /
  ("a" $7 / "b" $8 / "f" $12 / "n" $10 / "r" $13 / "t" $9 / "v" $11) ->tochar /
  (LINEBREAK $10)->tochar

octal-escape-sequence <-- ('\' {octal-digit octal-digit^-2} $8)->tochar
hexadecimal-escape-sequence <-- ('\x' {hexadecimal-digit+} $16)->tochar

--------------------------------------------------------------------------------
-- String literals

string-literal <==
  encoding-prefix? string-suffix+
string-suffix <-- '"' {~s-char-sequence?~} '"' SKIP
encoding-prefix <-- 'u8' / [uUL]
s-char-sequence <-- s-char+
s-char <- [^"\%cn%cr] / escape-sequence

--------------------------------------------------------------------------------
-- Expressions

primary-expression <--
  string-literal /
  type-name /
  identifier /
  constant /
  statement-expression /
  `(` expression `)` /
  generic-selection

statement-expression <==
  '({'SKIP (label-statement / declaration / statement)* '})'SKIP

generic-selection <==
  `_Generic` @`(` @assignment-expression @`,` @generic-assoc-list @`)`

generic-assoc-list <==
  generic-association (`,` @generic-association)*

generic-association <==
  type-name `:` @assignment-expression /
  {`default`} `:` @assignment-expression

postfix-expression <--
  (postfix-expression-prefix postfix-expression-suffix*) ~> rfoldright

postfix-expression-prefix <--
  type-initializer  /
  primary-expression

type-initializer <==
  `(` type-name `)` `{` initializer-list? `,`? `}`

postfix-expression-suffix <--
  array-subscript /
  argument-expression /
  struct-or-union-member /
  pointer-member /
  post-increment /
  post-decrement

array-subscript <== `[` expression `]`
argument-expression <== `(` argument-expression-list `)`
struct-or-union-member <== `.` identifier-word
pointer-member <== `->` identifier-word
post-increment <== `++`
post-decrement <== `--`

argument-expression-list <==
  (assignment-expression (`,` assignment-expression)*)?

unary-expression <--
  unary-op /
  postfix-expression
unary-op <==
  ({`++`} / {`--`}) @unary-expression /
  ({`sizeof`}) unary-expression /
  ({`&`} / {`+`} / {`-`} / {`~`} / {`!`}) @cast-expression /
  {`*`} cast-expression /
  ({`sizeof`} / {`_Alignof`}) `(` type-name `)`

cast-expression <--
  op-cast /
  unary-expression
op-cast:binary-op <==
  `(` type-name `)` $'cast' cast-expression

multiplicative-expression <--
  (cast-expression op-multiplicative*) ~> foldleft
op-multiplicative:binary-op <==
  ({`/`} / {`%`}) @cast-expression /
  {`*`} cast-expression

additive-expression <--
  (multiplicative-expression op-additive*) ~> foldleft
op-additive:binary-op <==
  ({`+`} / {`-`}) @multiplicative-expression

shift-expression <--
  (additive-expression op-shift*) ~> foldleft
op-shift:binary-op <==
  ({`<<`} / {`>>`}) @additive-expression

relational-expression <--
  (shift-expression op-relational*) ~> foldleft
op-relational:binary-op <==
  ({`<=`} / {`>=`} / {`<`} / {`>`}) @shift-expression

equality-expression <--
  (relational-expression op-equality*) ~> foldleft
op-equality:binary-op <==
  ({`==`} / {`!=`}) @relational-expression

AND-expression <--
  (equality-expression op-AND*) ~> foldleft
op-AND:binary-op <==
  {`&`} @equality-expression

exclusive-OR-expression <--
  (AND-expression op-OR*) ~> foldleft
op-OR:binary-op <==
  {`^`} @AND-expression

inclusive-OR-expression <--
  (exclusive-OR-expression op-inclusive-OR*) ~> foldleft
op-inclusive-OR:binary-op <==
  {`|`} @exclusive-OR-expression

logical-AND-expression <--
  (inclusive-OR-expression op-logical-AND*) ~> foldleft
op-logical-AND:binary-op <==
  {`&&`} @inclusive-OR-expression

logical-OR-expression <--
  (logical-AND-expression op-logical-OR*) ~> foldleft
op-logical-OR:binary-op <==
  {`||`} @logical-AND-expression

conditional-expression <--
  (logical-OR-expression op-conditional?) ~> foldleft
op-conditional:ternary-op <==
  {`?`} @expression @`:` @conditional-expression

assignment-expression <--
  conditional-expression !assignment-operator /
  (unary-expression op-assignment+) ~> foldleft
op-assignment:binary-op <==
  assignment-operator @assignment-expression
assignment-operator <--
  {`=`} /
  {`*=`} /
  {`/=`} /
  {`%=`} /
  {`+=`} /
  {`-=`} /
  {`<<=`} /
  {`>>=`} /
  {`&=`} /
  {`^=`} /
  {`|=`}

expression <==
  assignment-expression (`,` @assignment-expression)*

constant-expression <--
  conditional-expression

--------------------------------------------------------------------------------
-- Declarations

declaration <==
  (
    typedef-declaration /
    type-declaration /
    static_assert-declaration
  )
  @`;`

extension-specifiers <==
  extension-specifier+

extension-specifier <==
  attribute / asm / tg-promote

attribute <==
  (`__attribute__` / `__attribute`) `(` @`(` attribute-list @`)` @`)` /
  `[` `[` attribute-list @`]` @`]`

attribute-list <--
  attribute-item (`,` attribute-item)*

tg-promote <==
  `__tg_promote` @`(` (expression / parameter-varargs) @`)`

attribute-item <==
  identifier-anyword (`(` expression `)`)?

asm <==
  (`__asm` / `__asm__`)
  (`__volatile__` / `volatile`)~?
  `(` asm-argument (`,` asm-argument)* @`)`

asm-argument <-- (
    string-literal /
    {`:`} /
    {`,`} /
    `[` expression @`]` /
    `(` expression @`)` /
    expression
  )+

typedef-declaration <==
  `typedef` @declaration-specifiers (typedef-declarator (`,` @typedef-declarator)*)?

type-declaration <==
  declaration-specifiers init-declarator-list?

declaration-specifiers <==
  ((type-specifier-width / declaration-specifiers-aux)* type-specifier /
    declaration-specifiers-aux* type-specifier-width
  ) (type-specifier-width / declaration-specifiers-aux)*

declaration-specifiers-aux <--
  storage-class-specifier /
  type-qualifier /
  function-specifier /
  alignment-specifier

init-declarator-list <==
  init-declarator (`,` init-declarator)*

init-declarator <==
  declarator (`=` initializer)?

storage-class-specifier <==
  {`extern`} /
  {`static`} /
  {`auto`} /
  {`register`} /
  (`_Thread_local` / `__thread`)->'_Thread_local'

type-specifier <==
  {`void`} /
  {`char`} /
  {`int`} /
  {`float`} /
  {`double`} /
  {`_Bool`} /
  atomic-type-specifier /
  struct-or-union-specifier /
  enum-specifier /
  typedef-name /
  typeof

type-specifier-width : type-specifier <==
  {`short`} /
  (`signed` / `__signed__`)->'signed' /
  {`unsigned`} /
  (`long` `long`)->'long long' /
  {`long`} /
  {`_Complex`} /
  {`_Imaginary`}

typeof <==
  (`typeof` / `__typeof` / `__typeof__`) @argument-expression

struct-or-union-specifier <==
  struct-or-union extension-specifiers~?
  (identifier-word struct-declaration-list? / $false struct-declaration-list)

struct-or-union <--
  {`struct`} / {`union`}

struct-declaration-list <==
  `{` (struct-declaration / static_assert-declaration)* @`}`

struct-declaration <==
  specifier-qualifier-list struct-declarator-list? @`;`

specifier-qualifier-list <==
  ((type-specifier-width / specifier-qualifier-aux)* type-specifier /
    specifier-qualifier-aux* type-specifier-width
  ) (type-specifier-width / specifier-qualifier-aux)*

specifier-qualifier-aux <--
  type-qualifier /
  alignment-specifier

struct-declarator-list <==
  struct-declarator (`,` struct-declarator)*

struct-declarator <==
  declarator (`:` @constant-expression)? /
  `:` $false @constant-expression

enum-specifier <==
  `enum` extension-specifiers~? (identifier-word~? `{` @enumerator-list `,`? @`}` / @identifier-word)

enumerator-list <==
  enumerator (`,` enumerator)*

enumerator <==
  enumeration-constant extension-specifiers~? (`=` @constant-expression)?

atomic-type-specifier <==
  `_Atomic` `(` type-name `)`

type-qualifier <==
  {`const`} /
  (`restrict` / `__restrict` / `__restrict__`)->'restrict' /
  {`volatile`} /
  {`_Atomic`} !`(` /
  extension-specifier

function-specifier <==
  (`inline` / `__inline` / `__inline__`)->'inline' /
  {`_Noreturn`}

alignment-specifier <==
  `_Alignas` `(` (type-name / constant-expression) `)`

declarator <==
  (pointer* direct-declarator) -> foldright
  extension-specifiers?

typedef-declarator:declarator <==
  (pointer* typedef-direct-declarator) -> foldright
  extension-specifiers?

direct-declarator <--
  ((identifier / `(` declarator `)`) direct-declarator-suffix*) ~> foldleft

typedef-direct-declarator <--
  ((typedef-identifier / `(` typedef-declarator `)`) direct-declarator-suffix*) ~> foldleft

direct-declarator-suffix <--
  declarator-subscript /
  declarator-parameters

declarator-subscript <==
  `[` subscript-qualifier-list~? (assignment-expression / pointer)~? @`]`

subscript-qualifier-list <==
  (type-qualifier / &`static` storage-class-specifier)+

declarator-parameters <==
  `(` parameter-type-list `)` /
  `(` identifier-list? `)`

pointer <==
  extension-specifiers~? `*` type-qualifier-list~?

type-qualifier-list <==
  type-qualifier+

parameter-type-list <==
  parameter-list (`,` parameter-varargs)?

parameter-varargs <==
  `...`

parameter-list <--
  parameter-declaration (`,` parameter-declaration)*

parameter-declaration <==
  declaration-specifiers (declarator / abstract-declarator?)

identifier-list <==
  identifier-list-item (`,` @identifier-list-item)*

identifier-list-item <--
  identifier / `(` type-name @`)`

type-name <==
  specifier-qualifier-list abstract-declarator?

abstract-declarator:declarator <==
  (
    (pointer+ direct-abstract-declarator?) -> foldright /
    direct-abstract-declarator
  ) extension-specifiers?

direct-abstract-declarator <--
  (
    `(` abstract-declarator `)` direct-declarator-suffix* /
    direct-declarator-suffix+
  ) ~> foldleft

typedef-name <==
  &(identifier => is_typedef) identifier

typedef-identifier <==
  &(identifier => set_typedef) identifier

initializer <==
  assignment-expression /
  `{` initializer-list? `,`? @`}`

initializer-list <==
  initializer-item (`,` initializer-item)*

initializer-item <--
  designation /
  initializer

designation <==
  designator-list `=` @initializer

designator-list <==
  designator+

designator <--
  subscript-designator /
  member-designator

subscript-designator <==
  `[` @constant-expression @`]`

member-designator <==
  `.` @identifier-word

static_assert-declaration <==
  `_Static_assert` @`(` @constant-expression (`,` @string-literal)? @`)`

--------------------------------------------------------------------------------
-- Statements

statement <--
  label-statement /
  case-statement /
  default-statement /
  compound-statement /
  expression-statement /
  if-statement /
  switch-statement /
  while-statement /
  do-while-statement /
  for-statement /
  goto-statement /
  continue-statement /
  break-statement /
  return-statement /
  asm-statement /
  attribute /
  `;`

label-statement <==
  identifier `:`

case-statement <==
  `case` @constant-expression @`:` statement?

default-statement <==
  `default` @`:` statement?

compound-statement <==
  `{` (label-statement / declaration / statement)* @`}`

expression-statement <==
  expression @`;`

if-statement <==
  `if` @`(` @expression @`)` @statement (`else` @statement)?

switch-statement <==
  `switch` @`(` @expression @`)` @statement

while-statement <==
  `while` @`(` @expression @`)` @statement

do-while-statement <==
  `do` @statement @`while` @`(` @expression @`)` @`;`

for-statement <==
  `for` @`(` (declaration / expression~? @`;`) expression~? @`;` expression~? @`)` @statement

goto-statement <==
  `goto` constant-expression @`;`

continue-statement <==
  `continue` @`;`

break-statement <==
  `break` @`;`

return-statement <==
  `return` expression? @`;`

asm-statement <==
  asm @`;`

--------------------------------------------------------------------------------
-- External definitions

translation-unit <==
  external-declaration*

external-declaration <--
  function-definition /
  declaration /
  `;`

function-definition <==
  declaration-specifiers declarator declaration-list compound-statement

declaration-list <==
  declaration*
]==]

-- List of syntax errors
local SyntaxErrorLabels = {
  ["UnexpectedSyntax"] = "unexpected syntax",
}

-- Extra builtin types (in GCC/Clang).
local builtin_typedefs = {
  __builtin_va_list = true,
  __auto_type = true,
  __int128 = true, __int128_t = true,
  _Float32 = true, _Float32x = true,
  _Float64 = true, _Float64x = true,
  __float128 = true, _Float128 = true,
}

-- Parsing typedefs identifiers in C11 requires context information.
local typedefs

-- Clear typedefs.
local function init_typedefs()
  typedefs = {}
  for k in pairs(builtin_typedefs) do
    typedefs[k] = true
  end
end

local Defs = {}

-- Checks whether an identifier node is a typedef.
function Defs.is_typedef(_, _, node)
  return typedefs[node[1]] == true
end

-- Set an identifier as a typedef.
function Defs.set_typedef(_, _, node)
  typedefs[node[1]] = true
  return true
end

-- Compile grammar.
local lpegrex = require 'lpegrex'
local patt = lpegrex.compile(Grammar, Defs)

--[[
Parse C11 source code into an AST.
The source code must be already preprocessed (preprocessor directives will be ignored).
]]
local function parse(source, name)
  init_typedefs()
  local ast, errlabel, errpos = patt:match(source)
  typedefs = nil
  if not ast then
    name = name or '<source>'
    local lineno, colno, line = lpegrex.calcline(source, errpos)
    local colhelp = string.rep(' ', colno-1)..'^'
    local errmsg = SyntaxErrorLabels[errlabel] or errlabel
    error('syntax error: '..name..':'..lineno..':'..colno..': '..errmsg..
          '\n'..line..'\n'..colhelp)
  end
  return ast
end

return parse
