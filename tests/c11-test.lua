local parse_c11 = require 'parsers.c11'
local astutil = require 'parsers.astutil'
local lester = require 'tests.lester'

local describe, it = lester.describe, lester.it

local function eqast(source, expected)
  local aststr = astutil.ast2string(parse_c11(source))
  expected = expected:gsub('^%s+', ''):gsub('%s+$', '')
  if not aststr:find(expected, 1, true) then
    error('expected to match second in first value\nfirst value:\n'..aststr..'\nsecond value:\n'..expected)
  end
end

describe('c11 parser', function()

it("basic", function()
  eqast([[]], [[-]])
  eqast([[/* comment */]], [[-]])
  eqast([[// comment]], [[-]])
end)

it("escape sequence", function()
  eqast([[const char* s = "\'\"\?\a\b\f\n\r\t\v\\\000\xffff";]],
        [["\\\'\\\"\\?\\a\\b\\f\\n\\r\\t\\v\\\\\\000\\xffff"]])
end)

it("external declaration", function()
  eqast([[int a;]], [[
translation-unit
| declaration
| | type-declaration
| | | declaration-specifiers
| | | | type-specifier
| | | | | "int"
| | | init-declarator-list
| | | | init-declarator
| | | | | declarator
| | | | | | identifier
| | | | | | | "a"
]])
  eqast([[void main(){}]], [[
translation-unit
| function-definition
| | declaration-specifiers
| | | type-specifier
| | | | "void"
| | declarator
| | | declarator-parameters
| | | | identifier
| | | | | "main"
| | declaration-list
| | compound-statement
]])
  eqast([[_Static_assert(x, "x");]], [[
translation-unit
| declaration
| | static_assert-declaration
| | | identifier
| | | | "x"
| | | string-literal
| | | | "x"
]])
end)

it("expression statement", function()
  eqast([[void main() {a;;}]], [[
| | | expression-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
]])
end)

it("selection statement", function()
  eqast([[void main() {if(a) {} else if(b) {} else {}}]], [[
| | | if-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
| | | | compound-statement
| | | | if-statement
| | | | | expression
| | | | | | identifier
| | | | | | | "b"
| | | | | compound-statement
| | | | | compound-statement
]])
  eqast([[void main() {switch(a) {case A: default: break;}}]], [[
| | | switch-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
| | | | compound-statement
| | | | | case-statement
| | | | | | identifier
| | | | | | | "A"
| | | | | | default-statement
| | | | | | | break-statement
]])
end)

it("iteration statement", function()
  eqast([[void main() {while(a) {};}]], [[
| | | while-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
| | | | compound-statement
]])
  eqast([[void main() {do{} while(a);}]], [[
| | | do-while-statement
| | | | compound-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
]])
  eqast([[void main() {for(;;) {}}]], [[
| | | for-statement
| | | | false
| | | | false
| | | | false
| | | | compound-statement
]])
  eqast([[void main() {for(i=10;i;i--) {}}]], [[
| | | for-statement
| | | | expression
| | | | | binary-op
| | | | | | identifier
| | | | | | | "i"
| | | | | | "="
| | | | | | integer-constant
| | | | | | | "10"
| | | | expression
| | | | | identifier
| | | | | | "i"
| | | | expression
| | | | | post-decrement
| | | | | | identifier
| | | | | | | "i"
| | | | compound-statement
]])
end)

it("jump statement", function()
  eqast([[void main() {continue;}]], "continue-statement")
  eqast([[void main() {break;}]], "break-statement")
  eqast([[void main() {return;}]], "return-statement")
  eqast([[void main() {return a;}]], [[
| | | return-statement
| | | | expression
| | | | | identifier
| | | | | | "a"
]])
  eqast([[void main() {a: goto a;}]], [[
| | | label-statement
| | | | identifier
| | | | | "a"
| | | goto-statement
| | | | identifier
| | | | | "a"
]])

end)

it("label with typedefs", function()
  eqast([[
// namespaces.c
typedef int S, T, U;
struct S { int T; };
union U { int x; };
void f(void) {
  // The following uses of S, T, U are correct, and have no
  // effect on the visibility of S, T, U as typedef names.
  struct S s = { .T = 1 };
  T: s.T = 2;
  union U u = { 1 };
  goto T;
  // S, T and U are still typedef names:
  S ss = 1; T tt = 1; U uu = 1;
}
]], [[
| | | label-statement
| | | | identifier
| | | | | "T"
]])

end)

end)
