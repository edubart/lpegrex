local rex = require 'lpegrex'
local c = rex.compile([[
chunk         <-- SHEBANG? SKIP Block (!.)^UnexpectedSyntax

Block         <== ( Label / Return / Break / Goto / Do / While / Repeat / If / For / ForIn
                  / FuncDef / FuncDecl / VarDecl / Assign / callstat / `;`)*
Label         <== `::` @NAME @`::`
Return        <== `return` exprlist?
Break         <== `break`
Goto          <== `goto` @NAME
Do            <== `do` Block @`end`
While         <== `while` @expr @`do` Block @`end`
Repeat        <== `repeat` Block @`until` @expr
If            <== `if` @expr @`then` Block (`elseif` @expr @`then` Block)* (`else` Block)? @`end`
For           <== `for` Id `=` @expr @`,` @expr (`,` @expr)? @`do` Block @`end`
ForIn         <== `for` @idlist `in` @exprlist @`do` Block @`end`
FuncDef       <== `function` @funcname funcbody
FuncDecl      <== `local` `function` @Id funcbody
VarDecl       <== `local` @iddecllist (`=` @exprlist)?
Assign        <== varlist `=` @exprlist
callstat      <-- (primaryexpr (indexsuffix+ callsuffix / callsuffix)+) ~> rfoldright

Number        <== NUMBER
String        <== STRING
Boolean       <== `false` -> tofalse / `true` -> totrue
Nil           <== `nil`
Varargs       <== `...`
Id            <== NAME
IdDecl        <== NAME (`<` @NAME @`>`)?
Function      <== `function` funcbody
Table         <== `{` (field (fieldsep field)* fieldsep?)? @`}`
Paren         <== `(` expr `)`
Pair          <== `[` @expr @`]` `=` @expr / NAME `=` @expr
Call          <== callargs
CallMethod    <== `:` @NAME @callargs
DotIndex      <== `.` @NAME
ColonIndex    <== `:` @NAME
KeyIndex      <== `[` @expr @`]`

funcname      <-- (Id DotIndex* ColonIndex?) ~> rfoldright
funcbody      <-- @`(` funcargs @`)` Block @`end`
field         <-- Pair / expr
fieldsep      <-- `,` / `;`
var           <-- (primaryexpr (callsuffix+ indexsuffix / indexsuffix)+) ~> rfoldright / Id

callargs      <-| `(` (expr (`,` @expr)*)? `)` / Table / String
idlist        <-| Id (`,` @Id)*
iddecllist    <-| IdDecl (`,` @IdDecl)*
funcargs      <-| (Id (`,` Id)* (`,` @Varargs)? / Varargs)?
exprlist      <-| expr (`,` @expr)*
varlist       <-| var (`,` @var)*

op_or     :BinaryOp <== `or`->'or' expr_and
op_and    :BinaryOp <== `and`->'and' expr_cmp
op_cmp    :BinaryOp <== (`==`->'eq' / `~=`->'ne' / `<=`->'le' / `>=`->'ge' / `<`->'lt' / `>`->'gt') expr_bor
op_bor    :BinaryOp <== `|`->'bor' expr_bxor
op_bxor   :BinaryOp <== `~`->'bxor' expr_band
op_band   :BinaryOp <== `&`->'band' expr_bshift
op_bshift :BinaryOp <== (`<<`->'shl' / `>>`->'shr') expr_concat
op_concat :BinaryOp <== `..`->'concat' expr_concat
op_arit   :BinaryOp <== (`+`->'add' / `-`->'sub') expr_fact
op_fact   :BinaryOp <== (`*`->'mul' / `//`->'idiv' / `/`->'div' / `%`->'mod') expr_unary
op_pow    :BinaryOp <== `^`->'pow' expr_unary
op_unary  :UnaryOp  <== `not`->'not' / `#`->'len' / `-`->'unm' / `~`->'bnot'

expr          <-- expr_or
expr_or       <-- (expr_and op_or*) ~> foldleft
expr_and      <-- (expr_cmp op_and*) ~> foldleft
expr_cmp      <-- (expr_bor op_cmp*) ~> foldleft
expr_bor      <-- (expr_bxor op_bor*) ~> foldleft
expr_bxor     <-- (expr_band op_bxor*) ~> foldleft
expr_band     <-- (expr_bshift op_band*) ~> foldleft
expr_bshift   <-- (expr_concat op_bshift*) ~> foldleft
expr_concat   <-- (expr_arit op_concat?) ~> foldleft
expr_arit     <-- (expr_fact op_arit*) ~> foldleft
expr_fact     <-- (expr_unary op_fact*) ~> foldleft
expr_unary    <-- (op_unary* expr_pow) -> foldright
expr_pow      <-- (simplexpr op_pow?) ~> foldleft
simplexpr     <-- Nil / Boolean / Number / String / Varargs / Function / Table / suffixedexpr
suffixedexpr  <-- (primaryexpr (indexsuffix / callsuffix)*) ~> rfoldright
primaryexpr   <-- Id / Paren
indexsuffix   <-- DotIndex / KeyIndex
callsuffix    <-- Call / CallMethod

STRING        <-- (LONG_STRING / SHRT_STRING) SKIP
SHRT_STRING   <-- SHRT_OPEN {~ SHRT_CONTENT ~} @SHRT_CLOSE
SHRT_CONTENT  <-- (ESCAPE_SEQ / !(SHRT_CLOSE / LINEBREAK) .)*
SHRT_OPEN     <-- {:qe: ['"] :}
SHRT_CLOSE    <-- =qe
LONG_STRING   <-- LONG_OPEN {LONG_CONTENT} @LONG_CLOSE
LONG_CONTENT  <-- (!LONG_CLOSE .)*
LONG_OPEN     <-- '[' {:eq: '='*:} '[' LINEBREAK?
LONG_CLOSE    <-- ']' =eq ']'
ESCAPE_SEQ    <-- '\' -> '' @ESCAPE
ESCAPE        <-- ('a' $7 / 'b' $8 / 't' $9 / 'n' $10 / 'v' $11 / 'f' $12 / 'r' $13) -> tochar /
                  (LINEBREAK $10) -> tochar /
                  ('z' %s*) -> '' /
                  (%d %d^-1 !%d / [012] %d^2) -> tochar /
                  ('x' {%x^2} $16) -> tochar /
                  ('u' '{' {%x^+1} '}' $16) -> tochar

NUMBER        <-- {HEX_NUMBER / DEC_NUMBER} -> tonumber SKIP
HEX_NUMBER    <-- '0' [xX] @HEX_PREFIX ([pP] @EXP_DIGITS)?
HEX_PREFIX    <-- %x+ '.'? %x+? / '.' %x+
DEC_NUMBER    <-- DEC_PREFIX ([eE] @EXP_DIGITS)?
DEC_PREFIX    <-- %d+ '.'? %d+? / '.' %d+
EXP_DIGITS    <-- [+-]? %d+

NAME          <-- !KEYWORD {NAME_PREFIX NAME_SUFFIX?} SKIP
NAME_PREFIX   <-- [_%a]
NAME_SUFFIX   <-- [_%w]+

COMMENT       <-- '--' (LONG_COMMENT / SHRT_COMMENT)
LONG_COMMENT  <-- LONG_OPEN LONG_CONTENT LONG_CLOSE
SHRT_COMMENT  <-- (!LINEBREAK .)* LINEBREAK?

SHEBANG       <-- '#!' (!LINEBREAK .)* LINEBREAK?
LINEBREAK     <-- %nl %cr / %cr %nl / %nl / %cr
SKIP          <-- (%s+ / COMMENT)*
]])

local function prettyprint(node, indent)
  indent = indent or ''
  for i=1,#node do
    local child = node[i]
    local ty = type(child)
    if ty == 'table' then
      if child.tag then
        print(indent..child.tag)
      else
        print(indent..'-')
      end
      prettyprint(child, indent..'  ')
    elseif ty == 'string' then
      print(indent..'"'..tostring(child)..'"')
    elseif ty == 'number' or ty == 'boolean' or ty == 'nil' then
      print(indent..tostring(child))
    end
  end
end

local source = [[
-- defines a factorial function
function fact (n)
  if n == 0 then
    return 1
  else
    return n * fact(n-1)
  end
end

print("enter a number:")
a = io.read("*number")        -- read a number
print(fact(a))
]]

local ast, err = c:match(source)
assert(ast, err)
prettyprint(ast)
