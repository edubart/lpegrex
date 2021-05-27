local LUA_PEG = [[
chunk         <-- SHEBANG? SKIP Block (!.)^UnexpectedSyntax

Block         <== ( Label / Return / Break / Goto / Do / While / Repeat / If / ForNum / ForIn
                  / FuncDef / FuncDecl / VarDecl / Assign / callstat / `;`)*
Label         <== `::` @NAME @`::`
Return        <== `return` exprlist?
Break         <== `break`
Goto          <== `goto` @NAME
Do            <== `do` Block @`end`
While         <== `while` @expr @`do` Block @`end`
Repeat        <== `repeat` Block @`until` @expr
If            <== `if` @expr @`then` Block (`elseif` @expr @`then` Block)* (`else` Block)? @`end`
ForNum        <== `for` Id `=` @expr @`,` @expr (`,` @expr)? @`do` Block @`end`
ForIn         <== `for` @idlist `in` @exprlist @`do` Block @`end`
FuncDef       <== `function` @funcname funcbody
FuncDecl      <== `local` `function` @Id funcbody
VarDecl       <== `local` @iddecllist (`=` @exprlist)?
Assign        <== varlist `=` @exprlist
callstat      <-- (primaryexpr (indexsuffix+ callsuffix / callsuffix)+) ~> rfoldright

Number        <== {HEX_NUMBER / DEC_NUMBER} -> tonumber SKIP
String        <== (LONG_STRING / SHRT_STRING) SKIP
Boolean       <== `false` -> tofalse / `true` -> totrue
Nil           <== `nil`
Varargs       <== `...`
Id            <== NAME
IdDecl        <== NAME (`<` @NAME @`>`)?
Function      <== `function` funcbody
Table         <== `{` (field (fieldsep field)* fieldsep?)? @`}`
Paren         <== `(` @expr @`)`
Pair          <== `[` @expr @`]` @`=` @expr / NAME `=` @expr
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
primaryexpr   <-- Id / Paren
indexsuffix   <-- DotIndex / KeyIndex
callsuffix    <-- Call / CallMethod
callargs      <-| `(` (expr (`,` @expr)*)? @`)` / Table / String
idlist        <-| Id (`,` @Id)*
iddecllist    <-| IdDecl (`,` @IdDecl)*
funcargs      <-| (Id (`,` Id)* (`,` Varargs)? / Varargs)?
exprlist      <-| expr (`,` @expr)*
varlist       <-| var (`,` @var)*

expr          <-- expr_or
expr_or       <-- (expr_and op_or*) ~> foldleft
expr_and      <-- (expr_cmp op_and*) ~> foldleft
expr_cmp      <-- (expr_bor op_cmp*) ~> foldleft
expr_bor      <-- (expr_bxor op_bor*) ~> foldleft
expr_bxor     <-- (expr_band op_bxor*) ~> foldleft
expr_band     <-- (expr_bshift op_band*) ~> foldleft
expr_bshift   <-- (expr_concat op_bshift*) ~> foldleft
expr_concat   <-- (expr_arit op_concat*) ~> foldleft
expr_arit     <-- (expr_fact op_arit*) ~> foldleft
expr_fact     <-- (expr_unary op_fact*) ~> foldleft
expr_unary    <-- (op_unary* expr_pow) -> foldright
expr_pow      <-- (simplexpr op_pow*) ~> foldleft
simplexpr     <-- Nil / Boolean / Number / String / Varargs / Function / Table / suffixedexpr
suffixedexpr  <-- (primaryexpr (indexsuffix / callsuffix)*) ~> rfoldright

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

LONG_STRING   <-- LONG_OPEN {LONG_CONTENT} @LONG_CLOSE
LONG_CONTENT  <-- (!LONG_CLOSE .)*
LONG_OPEN     <-- '[' {:eq: '='*:} '[' LINEBREAK?
LONG_CLOSE    <-- ']' =eq ']'
SHRT_STRING   <-- SHRT_OPEN {~ SHRT_CONTENT ~} @SHRT_CLOSE
SHRT_OPEN     <-- {:qe: ['"] :}
SHRT_CONTENT  <-- (ESCAPE_SEQ / !(SHRT_CLOSE / LINEBREAK) .)*
SHRT_CLOSE    <-- =qe
ESCAPE_SEQ    <-- '\' -> '' @ESCAPE
ESCAPE        <-- [\'"] /
                  ('a' $7 / 'b' $8 / 't' $9 / 'n' $10 / 'v' $11 / 'f' $12 / 'r' $13) -> tochar /
                  (LINEBREAK $10) -> tochar /
                  ('z' %s*) -> '' /
                  (%d %d^-1 !%d / [012] %d^2) -> tochar /
                  ('x' {%x^2} $16) -> tochar /
                  ('u' '{' {%x^+1} '}' $16) -> tochar

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
EXTRA_TOKENS  <-- `[[` `[=` `--` -- unused rule, here just to force defining these tokens
]]

-- List of syntax errors
local SyntaxErrorLabels = {
  ["Expected_::"]         = "unclosed label, did you forget `::`?",
  ["Expected_)"]          = "unclosed parenthesis, did you forget a `)`?",
  ["Expected_>"]          = "unclosed angle bracket, did you forget a `>`?",
  ["Expected_]"]          = "unclosed square bracket, did you forget a `]`?",
  ["Expected_}"]          = "unclosed curly brace, did you forget a `}`?",
  ["Expected_LONG_CLOSE"] = "unclosed long string or comment, did your forget a ']]'?",
  ["Expected_SHRT_CLOSE"] = "unclosed short string or comment, did your forget a quote?",
  ["Expected_("]          = "expected parenthesis token `(`",
  ["Expected_,"]          = "expected comma token `,`",
  ["Expected_="]          = "expected equals token `=`",
  ["Expected_callargs"]   = "expected a list of arguments",
  ["Expected_expr"]       = "expected an expression",
  ["Expected_exprlist"]   = "expected a list of expressions",
  ["Expected_funcname"]   = "expected a function name",
  ["Expected_do"]         = "expected `do` keyword to begin a statement block",
  ["Expected_end"]        = "expected `end` keyword to close a statement block",
  ["Expected_then"]       = "expected `then` keyword to begin a statement block",
  ["Expected_until"]      = "expected `until` keyword to close repeat statement",
  ["Expected_ESCAPE"]     = "malformed escape sequence",
  ["Expected_EXP_DIGITS"] = "malformed exponential number",
  ["Expected_HEX_PREFIX"] = "malformed hexadecimal number",
  ["Expected_Id"]         = "expected an identifier name",
  ["Expected_NAME"]       = "expected an identifier name",
  ["Expected_IdDecl"]     = "expected an identifier declaration name",
  ["Expected_iddecllist"] = "expected a list of identifier declaration names",
  ["Expected_idlist"]     = "expected a list of identifier names",
  ["Expected_var"]        = "expected a variable",
  ["UnexpectedSyntax"]    = "unexpected syntax",
}

-- Load source file
local filename = arg[1]
if not filename then print 'please pass a lua filename as argument' os.exit(false) end
local file = io.open(filename)
if not file then print('failed to open file: '..filename) os.exit(false) end
local source = file:read('a')

-- Compile grammar
local lpegrex = require 'lpegrex'
local patt = lpegrex.compile(LUA_PEG)

-- Parse source
local ast, errlabel, errpos = patt:match(source)
if not ast then
  local lineno, colno, line = lpegrex.calcline(source, errpos)
  local colhelp = string.rep(' ', colno-1)..'^'
  local errmsg = SyntaxErrorLabels[errlabel] or errlabel
  error('syntax error: '..filename..':'..lineno..':'..colno..': '..errmsg..
        '\n'..line..'\n'..colhelp)
end

-- Print its AST
local function printast(node, indent)
  indent = indent or ''
  if node.tag then
    print(indent..node.tag)
  else
    print(indent..'-')
  end
  indent = indent..'| '
  for i=1,#node do
    local child = node[i]
    local ty = type(child)
    if ty == 'table' then
      printast(child, indent)
    elseif ty == 'string' then
      local escaped = child
        :gsub([[(['"])]], '\\%1')
        :gsub('\n', '\\n'):gsub('\t', '\\t')
        :gsub('[^ %w%p]', function(s)
          return string.format('\\x%02x', string.byte(s))
        end)
      print(indent..'"'..escaped..'"')
    else
      print(indent..tostring(child))
    end
  end
end
printast(ast)
