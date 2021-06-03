--[[
This grammar is based on Lua 5.4
As seen in https://www.lua.org/manual/5.4/manual.html#9
]]
local Grammar = [==[
chunk         <-- SHEBANG? SKIP Block (!.)^UnexpectedSyntax

Block         <== ( Label / Return / Break / Goto / Do / While / Repeat / If / ForNum / ForIn
                  / FuncDef / FuncDecl / VarDecl / Assign / call / `;`)*
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

Number        <== NUMBER->tonumber SKIP
String        <== STRING SKIP
Boolean       <== `false`->tofalse / `true`->totrue
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

indexsuffix   <-- DotIndex / KeyIndex
callsuffix    <-- Call / CallMethod

var           <-- (exprprimary (callsuffix+ indexsuffix / indexsuffix)+)~>rfoldright / Id
call          <-- (exprprimary (indexsuffix+ callsuffix / callsuffix)+)~>rfoldright
exprsuffixed  <-- (exprprimary (indexsuffix / callsuffix)*)~>rfoldright
funcname      <-- (Id DotIndex* ColonIndex?)~>rfoldright

funcbody      <-- @`(` funcargs @`)` Block @`end`
field         <-- Pair / expr
fieldsep      <-- `,` / `;`

callargs      <-| `(` (expr (`,` @expr)*)? @`)` / Table / String
idlist        <-| Id (`,` @Id)*
iddecllist    <-| IdDecl (`,` @IdDecl)*
funcargs      <-| (Id (`,` Id)* (`,` Varargs)? / Varargs)?
exprlist      <-| expr (`,` @expr)*
varlist       <-| var (`,` @var)*

opor     :BinaryOp <== `or`->'or' @exprand
opand    :BinaryOp <== `and`->'and' @exprcmp
opcmp    :BinaryOp <== (`==`->'eq' / `~=`->'ne' / `<=`->'le' / `>=`->'ge' / `<`->'lt' / `>`->'gt') @exprbor
opbor    :BinaryOp <== `|`->'bor' @exprbxor
opbxor   :BinaryOp <== `~`->'bxor' @exprband
opband   :BinaryOp <== `&`->'band' @exprbshift
opbshift :BinaryOp <== (`<<`->'shl' / `>>`->'shr') @exprconcat
opconcat :BinaryOp <== `..`->'concat' @exprconcat
oparit   :BinaryOp <== (`+`->'add' / `-`->'sub') @exprfact
opfact   :BinaryOp <== (`*`->'mul' / `//`->'idiv' / `/`->'div' / `%`->'mod') @exprunary
oppow    :BinaryOp <== `^`->'pow' @exprunary
opunary  :UnaryOp  <== (`not`->'not' / `#`->'len' / `-`->'unm' / `~`->'bnot') @exprunary

expr          <-- expror
expror        <-- (exprand opor*)~>foldleft
exprand       <-- (exprcmp opand*)~>foldleft
exprcmp       <-- (exprbor opcmp*)~>foldleft
exprbor       <-- (exprbxor opbor*)~>foldleft
exprbxor      <-- (exprband opbxor*)~>foldleft
exprband      <-- (exprbshift opband*)~>foldleft
exprbshift    <-- (exprconcat opbshift*)~>foldleft
exprconcat    <-- (exprarit opconcat*)~>foldleft
exprarit      <-- (exprfact oparit*)~>foldleft
exprfact      <-- (exprunary opfact*)~>foldleft
exprunary     <-- opunary / exprpow
exprpow       <-- (exprsimple oppow*)~>foldleft
exprsimple    <-- Nil / Boolean / Number / String / Varargs / Function / Table / exprsuffixed
exprprimary   <-- Id / Paren

STRING        <-- STRING_SHRT / STRING_LONG
STRING_LONG   <-- {:LONG_OPEN {LONG_CONTENT} @LONG_CLOSE:}
STRING_SHRT   <-- {:QUOTE_OPEN {~QUOTE_CONTENT~} @QUOTE_CLOSE:}
QUOTE_OPEN    <-- {:qe: ['"] :}
QUOTE_CONTENT <-- (ESCAPE_SEQ / !(QUOTE_CLOSE / LINEBREAK) .)*
QUOTE_CLOSE   <-- =qe
ESCAPE_SEQ    <-- '\'->'' @ESCAPE
ESCAPE        <-- [\'"] /
                  ('n' $10 / 't' $9 / 'r' $13 / 'a' $7 / 'b' $8 / 'v' $11 / 'f' $12)->tochar /
                  ('x' {HEX_DIGIT^2} $16)->tochar /
                  ('u' '{' {HEX_DIGIT^+1} '}' $16)->toutf8char /
                  ('z' SPACE*)->'' /
                  (DEC_DIGIT DEC_DIGIT^-1 !DEC_DIGIT / [012] DEC_DIGIT^2)->tochar /
                  (LINEBREAK $10)->tochar

NUMBER        <-- {HEX_NUMBER / DEC_NUMBER}
HEX_NUMBER    <-- '0' [xX] @HEX_PREFIX ([pP] @EXP_DIGITS)?
DEC_NUMBER    <-- DEC_PREFIX ([eE] @EXP_DIGITS)?
HEX_PREFIX    <-- HEX_DIGIT+ ('.' HEX_DIGIT*)? / '.' HEX_DIGIT+
DEC_PREFIX    <-- DEC_DIGIT+ ('.' DEC_DIGIT*)? / '.' DEC_DIGIT+
EXP_DIGITS    <-- [+-]? DEC_DIGIT+

COMMENT       <-- '--' (COMMENT_LONG / COMMENT_SHRT)
COMMENT_LONG  <-- (LONG_OPEN LONG_CONTENT @LONG_CLOSE)->0
COMMENT_SHRT  <-- (!LINEBREAK .)*

LONG_CONTENT  <-- (!LONG_CLOSE .)*
LONG_OPEN     <-- '[' {:eq: '='*:} '[' LINEBREAK?
LONG_CLOSE    <-- ']' =eq ']'

NAME          <-- !KEYWORD {NAME_PREFIX NAME_SUFFIX?} SKIP
NAME_PREFIX   <-- [_a-zA-Z]
NAME_SUFFIX   <-- [_a-zA-Z0-9]+

SHEBANG       <-- '#!' (!LINEBREAK .)* LINEBREAK?
SKIP          <-- (SPACE+ / COMMENT)*
LINEBREAK     <-- %cn %cr / %cr %cn / %cn / %cr
SPACE         <-- %sp
HEX_DIGIT     <-- [0-9a-fA-F]
DEC_DIGIT     <-- [0-9]
EXTRA_TOKENS  <-- `[[` `[=` `--` -- unused rule, here just to force defining these tokens
]==]

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

-- Compile grammar
local lpegrex = require 'lpegrex'
local patt = lpegrex.compile(Grammar)

-- Parse Lua source into an AST.
local function parse(source, name)
  local ast, errlabel, errpos = patt:match(source)
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
