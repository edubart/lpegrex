--[[
This is the grammar for Nelua programming language,
it's superset of Lua 5.4, supporting type annotations.
See https://github.com/edubart/nelua-lang
]]

local Grammar = [==[
chunk           <-- SHEBANG? SKIP Block (!.)^UnexpectedSyntax

Block           <== ( FuncDecl / FuncDef /
                      locvardecl / glovardecl /
                      Preprocess / Return /
                      Do / Defer /
                      If / Switch /
                      ForNum / ForIn /
                      While / Repeat /
                      Break / Continue /
                      Goto / Label /
                      Assign / callstat / `;` )*

-- Statements
Label           <== `::` @name @`::`
Return          <== `return` exprs?
Break           <== `break`
Continue        <== `continue`
Goto            <== `goto` @name
Do              <== `do` Block @`end`
Defer           <== `defer` Block @`end`
While           <== `while` @expr @`do` Block @`end`
Repeat          <== `repeat` Block @`until` @expr
If              <== `if` @expr @`then` Block (`elseif` @expr @`then` Block)* (`else` Block)? @`end`
Switch          <== `switch` @expr `do`? @cases (`else` Block)? @`end`
cases           <-- (`case` @exprs @`then` Block)+
ForNum          <== `for` IdDecl `=` @expr @`,` cmp~? @expr (`,` @expr)~? @`do` Block @`end`
ForIn           <== `for` @iddecls @`in` @exprs @`do` Block @`end`
FuncDef         <== `function` @funcname @funcbody
funcbody        <-- `(` funcargs~? @`)` (`:` funcrets)~? annots~? Block @`end`
funcrets        <--`(` @typeexprs @`)` / @typeexpr
FuncDecl        <== ({`local`} / {`global`}) `function` @nameiddecl @funcbody
locvardecl : VarDecl <== {`local`} @iddecls (`=` @exprs)?
glovardecl : VarDecl <== {`global`} @gloiddecls (`=` @exprs)?
Assign          <== vars `=` @exprs
callstat        <-- call
Preprocess      <== PP_STRING SKIP

-- Simple expressions
Number          <== {HEX_NUMBER / BIN_NUMBER / DEC_NUMBER} name? SKIP
String          <== (SHRT_STRING / LONG_STRING) name? SKIP
Boolean         <== `true`->totrue / `false`->tofalse
Nil             <== `nil`
Varargs         <== `...`
Id              <== name
IdDecl          <== name (`:` @typeexpr)~? annots?
typeiddecl : IdDecl <== name `:` @typeexpr annots?
gloiddecl  : IdDecl <== (idsuffixed / name) (`:` @typeexpr)~? annots?
nameiddecl : IdDecl <== name
Function        <== `function` @funcbody
InitList        <== `{` (field (fieldsep field)* fieldsep?)? @`}`
field           <-- Pair / expr
Paren           <== `(` @expr @`)`
DoExpr          <== `(` `do` Block @`end` @`)`
Type            <== `@` @typeexpr

Pair            <== `[` @expr @`]` @`=` @expr / name `=` @expr / `=` @name
Annotation      <== name callargs?

-- Preprocessor replaceable nodes
PreprocessExpr  <== `#[` {@expr->0} @`]#`
PreprocessName  <== `#|` {@expr->0} @`|#`

-- Suffix nodes
Call            <== callargs
CallMethod      <== `:` @name @callargs
DotIndex        <== `.` @name
ColonIndex      <== `:` @name
KeyIndex        <== `[` @expr @`]`

indexsuffix     <-- DotIndex / KeyIndex
callsuffix      <-- Call / CallMethod

var             <-- (exprprim (callsuffix+ indexsuffix / indexsuffix)+)~>rfoldright / Id / deref
call            <-- (exprprim (indexsuffix+ callsuffix / callsuffix)+)~>rfoldright
exprsuffixed    <-- (exprprim (indexsuffix / callsuffix)*)~>rfoldright
idsuffixed      <-- (Id DotIndex+)~>rfoldright
funcname        <-- (Id DotIndex* ColonIndex?)~>rfoldright

-- List rules
callargs        <-| `(` (expr (`,` @expr)*)? @`)` / InitList / String / PreprocessExpr
iddecls         <-| IdDecl (`,` @IdDecl)*
funcargs        <-| IdDecl (`,` IdDecl)* (`,` VarargsType)? / VarargsType
gloiddecls      <-| gloiddecl (`,` @gloiddecl)*
exprs           <-| expr (`,` @expr)*
annots          <-| `<` @Annotation (`,` @Annotation)* @`>`
typeexprs       <-| typeexpr (`,` @typeexpr)*
vars            <-| var (`,` @var)*

-- Expression operators
opor      : BinaryOp  <== `or`->'or' @exprand
opand     : BinaryOp  <== `and`->'and' @exprcmp
opcmp     : BinaryOp  <== cmp @exprbor
opbor     : BinaryOp  <== `|`->'bor' @exprbxor
opbxor    : BinaryOp  <== `~`->'bxor' @exprband
opband    : BinaryOp  <== `&`->'band' @exprbshift
opbshift  : BinaryOp  <== (`<<`->'shl' / `>>>`->'asr' / `>>`->'shr') @exprconcat
opconcat  : BinaryOp  <== `..`->'concat' @exprconcat
oparit    : BinaryOp  <== (`+`->'add' / `-`->'sub') @exprfact
opfact    : BinaryOp  <== (`*`->'mul' / `///`->'tdiv' / `//`->'idiv' / `/`->'div' /
                           `%%%`->'tmod' / `%`->'mod') @exprunary
oppow     : BinaryOp  <== `^`->'pow' @exprunary
opunary   : UnaryOp   <== (`not`->'not' / `-`->'unm' / `#`->'len' /
                           `~`->'bnot' / `&`->'ref' / `$`->'deref') @exprunary
deref     : UnaryOp   <== `$`->'deref' @exprpow

-- Expression
expr            <-- expror
expror          <-- (exprand opor*)~>foldleft
exprand         <-- (exprcmp opand*)~>foldleft
exprcmp         <-- (exprbor opcmp*)~>foldleft
exprbor         <-- (exprbxor opbor*)~>foldleft
exprbxor        <-- (exprband opbxor*)~>foldleft
exprband        <-- (exprbshift opband*)~>foldleft
exprbshift      <-- (exprconcat opbshift*)~>foldleft
exprconcat      <-- (exprarit opconcat*)~>foldleft
exprarit        <-- (exprfact oparit*)~>foldleft
exprfact        <-- (exprunary opfact*)~>foldleft
exprunary       <-- opunary / exprpow
exprpow         <-- (exprsimple oppow*)~>foldleft
exprsimple      <-- Number / String / Type / InitList / Boolean /
                    Function / Nil / DoExpr / Varargs / exprsuffixed
exprprim        <-- Id / Paren / PreprocessExpr

-- Types
TypeId          <== name
RecordType      <== 'record' SKIP @`{` recordfields @`}`
UnionType       <== 'union' SKIP @`{` unionfields @`}`
EnumType        <== 'enum' SKIP (`(` @typeexpr @`)`)~? @`{` @enumfields @`}`
FuncType        <== 'function' SKIP @`(` functypeargs~? @`)`(`:` funcrets)?
ArrayType       <== 'array' SKIP @`(` @typeexpr (`,` @expr)? @`)`
PointerType     <== 'pointer' SKIP (`(` @typeexpr @`)`)?
VariantType     <== 'variant' SKIP `(` @typeexprs @`)`
VarargsType     <== `...` (`:` @typeexpr)?

RecordField     <== name @`:` @typeexpr
UnionField      <== name @`:` @typeexpr / typeexpr
EnumField       <== name (`=` @expr)?

-- Type list rules
recordfields    <-| (RecordField (fieldsep RecordField)* fieldsep?)?
unionfields     <-| (UnionField (fieldsep UnionField)* fieldsep?)?
enumfields      <-| EnumField (fieldsep EnumField)* fieldsep?
functypeargs    <-| functypearg (`,` functypearg)* (`,` VarargsType)? / VarargsType
typeargs        <-| typearg (`,` @typearg)*

functypearg     <-- typeiddecl / typeexpr
typearg         <-- typeexpr / `(` expr @`)` / expr

-- Type expression operators
typeopptr : PointerType   <== `*`
typeopopt : OptionalType  <== `?`
typeoparr : ArrayType     <== `[` expr? @`]`
typeopvar : VariantType   <== `|` @typeexprunary (`|` @typeexprunary)*
typeopgen : GenericType   <== `(` @typeargs @`)`

typeopunary     <-- typeopptr / typeopopt / typeoparr

-- Type expression
typeexpr        <-- typeexprvar
typeexprvar     <-- (typeexprunary typeopvar?)~>foldleft
typeexprunary   <-- (typeopunary* typexprsimple)->rfoldleft
typexprsimple   <-- RecordType / UnionType / EnumType / FuncType / ArrayType / PointerType /
                    VariantType / (typeexprprim typeopgen?)~>rfoldright
typeexprprim    <-- idsuffixed / TypeId / PreprocessExpr

-- Shared rules
name            <-- !KEYWORD {NAME_PREFIX NAME_SUFFIX?} SKIP / PreprocessName
cmp             <-- `==`->'eq' / `~=`->'ne' / `<=`->'le' / `<`->'lt' / `>=`->'ge' / `>`->'gt'
fieldsep        <-- `,` / `;`

-- Miscellaneous
LONG_STRING     <-- LONG_OPEN {LONG_CONTENT} @LONG_CLOSE
SHRT_STRING     <-- SHRT_OPEN {~SHRT_CONTENT~} @SHRT_CLOSE
SHRT_OPEN       <-- {:qe: ['"] :}
SHRT_CONTENT    <-- (ESCAPE_SEQ / !(SHRT_CLOSE / LINEBREAK) .)*
SHRT_CLOSE      <-- =qe
ESCAPE_SEQ      <-- '\'->'' @ESCAPE
ESCAPE          <-- [\'"] /
                    ('n' $10 / 't' $9 / 'r' $13 / 'a' $7 / 'b' $8 / 'v' $11 / 'f' $12)->tochar /
                    ('x' {HEX_DIGIT^2} $16)->tochar /
                    ('u' '{' {HEX_DIGIT^+1} '}' $16)->tochar /
                    ('z' SPACE*)->'' /
                    (DEC_DIGIT DEC_DIGIT^-1 !DEC_DIGIT / [012] DEC_DIGIT^2)->tochar /
                    (LINEBREAK $10)->tochar

-- Number
HEX_NUMBER      <-- '0' [xX] $16 @HEX_PREFIX ([pP] {@EXP_DIGITS})~?
BIN_NUMBER      <-- '0' [bB] $2 @BIN_PREFIX ([pP] @EXP_DIGITS)?
DEC_NUMBER      <-- $10 DEC_PREFIX ([eE] @EXP_DIGITS)?
HEX_PREFIX      <-- {HEX_DIGIT+} ('.' ({HEX_DIGIT+} / $'0'))~? / '.' $'0' {HEX_DIGIT+}
BIN_PREFIX      <-- {BIN_DIGITS} ('.' ({BIN_DIGITS} / $'0'))~? / '.' $'0' {BIN_DIGITS}
DEC_PREFIX      <-- {DEC_DIGIT+} ('.' ({DEC_DIGIT+} / $'0'))~? / '.' $'0' {DEC_DIGIT+}
EXP_DIGITS      <-- [+-]? DEC_DIGIT+

-- Long (used in string, comment and preprocessor)
LONG_OR_SHRT    <-- (LONG_OPEN LONG_CONTENT @LONG_CLOSE / LINE)
LONG_CONTENT    <-- (!LONG_CLOSE .)*
LONG_OPEN       <-- '[' {:eq: '='*:} '[' LINEBREAK?
LONG_CLOSE      <-- ']' =eq ']'

-- Miscellaneous
COMMENT         <-- '--' LONG_OR_SHRT
PP_STRING       <-- '##' LONG_OR_SHRT
SHEBANG         <-- '#!' LINE
SKIP            <-- (SPACE+ / COMMENT)*
LINE            <-- (!LINEBREAK .)* LINEBREAK?
LINEBREAK       <-- %cn %cr / %cr %cn / %cn / %cr
SPACE           <-- %sp
HEX_DIGIT       <-- [0-9a-fA-F]
BIN_DIGITS      <-- [01]+ !DEC_DIGIT
DEC_DIGIT       <-- [0-9]
NAME_PREFIX     <-- [_a-zA-Z%utf8seq]
NAME_SUFFIX     <-- [_a-zA-Z0-9%utf8seq]+
EXTRA_TOKENS    <-- `[[` `[=` `--` `##` -- Force defining these tokens.
]==]

-- List of syntax errors
local SyntaxErrorLabels = {
  ["Expected_do"]             = "expected `do` keyword to begin a statement block",
  ["Expected_then"]           = "expected `then` keyword to begin a statement block",
  ["Expected_end"]            = "expected `end` keyword to close a statement block",
  ["Expected_until"]          = "expected `until` keyword to close a `repeat` statement",
  ["Expected_cases"]          = "expected `case` keyword in `switch` statement",
  ["Expected_in"]             = "expected `in` keyword in `for` statement",
  ["Expected_Annotation"]     = "expected an annotation expression",
  ["Expected_expr"]           = "expected an expression",
  ["Expected_exprand"]        = "expected an expression for operator",
  ["Expected_exprcmp"]        = "expected an expression for operator",
  ["Expected_exprbor"]        = "expected an expression for operator",
  ["Expected_exprbxor"]       = "expected an expression for operator",
  ["Expected_exprband"]       = "expected an expression for operator",
  ["Expected_exprbshift"]     = "expected an expression for operator",
  ["Expected_exprconcat"]     = "expected an expression for operator",
  ["Expected_exprfact"]       = "expected an expression for operator",
  ["Expected_exprunary"]      = "expected an expression for operator",
  ["Expected_exprpow"]        = "expected an expression for operator",
  ["Expected_name"]           = "expected an identifier name",
  ["Expected_nameiddecl"]     = "expected an identifier name",
  ["Expected_IdDecl"]         = "expected an identifier declaration",
  ["Expected_typearg"]        = "expected an argument in type expression",
  ["Expected_typeexpr"]       = "expected a type expression",
  ["Expected_typeexprunary"]  = "expected a type expression",
  ["Expected_funcbody"]       = "expected a function body",
  ["Expected_funcname"]       = "expected a function name",
  ["Expected_gloiddecl"]      = "expected a global identifier declaration",
  ["Expected_var"]            = "expected a variable",
  ["Expected_enumfields"]     = "expected a field in `enum` type",
  ["Expected_typeargs"]       = "expected arguments in type expression",
  ["Expected_callargs"]       = "expected call arguments",
  ["Expected_exprs"]          = "expected expressions",
  ["Expected_typeexprs"]      = "expected type expressions",
  ["Expected_gloiddecls"]     = "expected global identifier declarations",
  ["Expected_iddecls"]        = "expected identifier declarations",
  ["Expected_("]              = "expected parenthesis `(`",
  ["Expected_,"]              = "expected comma `,`",
  ["Expected_:"]              = "expected colon `:`",
  ["Expected_="]              = "expected equals `=`",
  ["Expected_{"]              = "expected curly brace `{`",
  ["Expected_)"]              = "unclosed parenthesis, did you forget a `)`?",
  ["Expected_::"]             = "unclosed label, did you forget a `::`?",
  ["Expected_>"]              = "unclosed angle bracket, did you forget a `>`?",
  ["Expected_]"]              = "unclosed square bracket, did you forget a `]`?",
  ["Expected_}"]              = "unclosed curly brace, did you forget a `}`?",
  ["Expected_]#"]             = "unclosed preprocess expression, did you forget a `]#`?",
  ["Expected_|#"]             = "unclosed preprocess name, did you forget a `|#`?",
  ["Expected_LONG_CLOSE"]     = "unclosed long, did you forget a `]]`?",
  ["Expected_SHRT_CLOSE"]     = "unclosed string, did you forget a quote?",
  ["Expected_ESCAPE"]         = "malformed escape sequence",
  ["Expected_BIN_PREFIX"]     = "malformed binary number",
  ["Expected_EXP_DIGITS"]     = "malformed exponential number",
  ["Expected_HEX_PREFIX"]     = "malformed hexadecimal number",
  ["UnexpectedSyntax"]        = "unexpected syntax",
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
