--[[
This grammar is based on the CSV specification.
As seen in https://en.wikipedia.org/wiki/Comma-separated_values
]]
local Grammar = [==[
Csv           <-- rows (!.)^UnexpectedSyntax
rows          <-| Row (%nl Row)*
Row           <-| Column (',' Column)+
Column        <-- Number / QuotedString / String
QuotedString  <-- '"' {~ ('""' -> '"' / !'"' .)* ~} '"' COLUMN_END
Number        <-- {[+-]? (%d+ '.'? %d+? / '.' %d+) ([eE] [+-]? %d+)?} -> tonumber COLUMN_END
String        <-- {[^%nl,]*}
COLUMN_END    <-- ![^%nl,] / !.
]==]

-- List of syntax errors.
local SyntaxErrorLabels = {
  ["UnexpectedSyntax"]  = "unexpected syntax",
}

-- Compile grammar.
local lpegrex = require 'lpegrex'
local patt = lpegrex.compile(Grammar)

-- Parse CSV source into an AST.
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
