--[[
This grammar is based on the JSON specification.
As seen in https://www.json.org/json-en.html
]]
local Grammar = [==[
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
]==]

-- List of syntax errors.
local SyntaxErrorLabels = {
  ["UnexpectedSyntax"]  = "unexpected syntax",
  ["Expected_Member"]   = "expected an object member",
  ["Expected_Value"]    = "expected a value",
  ["Expected_ESCAPE"]   = "expected a valid escape sequence",
  ["Expected_}"]        = "unclosed curly bracket `}`",
  ["Expected_]"]        = "unclosed square bracket `]`",
  ['Expected_"']        = 'unclosed string quotes `"`',
}

-- Compile grammar.
local lpegrex = require 'lpegrex'
local patt = lpegrex.compile(Grammar)

-- Parse JSON source into an AST.
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
