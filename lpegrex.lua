--[[
LPeg Regular Expressions Extended
Eduardo Bart - edub4rt@gmail.com
https://github.com/edubart/lpegrex
See end of file for LICENSE.
]]

local lpeg = require 'lpeglabel'

-- LPegRex module table.
local lpegrex = {}

-- Cache tables for `match`, `find` and `gsub`.
local mcache, fcache, gcache

-- Predefined patterns.
local Predef = {
  any = lpeg.P(1),
  nl = lpeg.P'\n',
}

-- Error descripts.
local ErrorDescs = {
  NoPatt = "no pattern found",
  ExtraChars = "unexpected characters after the pattern",

  ExpPatt1 = "expected a pattern after '/'",
  ExpPatt2 = "expected a pattern after '&'",
  ExpPatt3 = "expected a pattern after '!'",
  ExpPatt4 = "expected a pattern after '('",
  ExpPatt5 = "expected a pattern after ':'",
  ExpPatt6 = "expected a pattern after '{~'",
  ExpPatt7 = "expected a pattern after '{|'",
  ExpPatt8 = "expected a pattern after '<-'",

  ExpPattOrClose = "expected a pattern or closing '}' after '{'",

  ExpNumName = "expected a number, '+', '-' or a name (no space) after '^'",
  ExpCap = "expected a string, number, '{}' or name after '->'",

  ExpName1 = "expected the name of a rule after '=>'",
  ExpName2 = "expected the name of a rule after '=' (no space)",
  ExpName3 = "expected the name of a rule after '<' (no space)",
  ExpName4 = "expected the name of a rule after '$' (no space)",

  ExpLab1 = "expected a label after '{'",

  ExpNameOrLab = "expected a name or label after '%' (no space)",

  ExpItem = "expected at least one item after '[' or '^'",

  MisClose1 = "missing closing ')'",
  MisClose2 = "missing closing ':}'",
  MisClose3 = "missing closing '~}'",
  MisClose4 = "missing closing '|}'",
  MisClose5 = "missing closing '}'",  -- for the captures
  MisClose6 = "missing closing '>'",
  MisClose7 = "missing closing '}'",  -- for the labels
  MisClose8 = "missing closing ']'",

  MisTerm1 = "missing terminating single quote",
  MisTerm2 = "missing terminating double quote",
  MisTerm3 = "missing terminating backtick quote",
}

-- Updates the pre-defined character classes to the current locale.
function lpegrex.updatelocale()
  lpeg.locale(Predef)
  Predef.a = Predef.alpha
  Predef.c = Predef.cntrl
  Predef.d = Predef.digit
  Predef.g = Predef.graph
  Predef.l = Predef.lower
  Predef.p = Predef.punct
  Predef.s = Predef.space
  Predef.u = Predef.upper
  Predef.w = Predef.alnum
  Predef.x = Predef.xdigit
  Predef.A = Predef.any - Predef.a
  Predef.C = Predef.any - Predef.c
  Predef.D = Predef.any - Predef.d
  Predef.G = Predef.any - Predef.g
  Predef.L = Predef.any - Predef.l
  Predef.P = Predef.any - Predef.p
  Predef.S = Predef.any - Predef.s
  Predef.U = Predef.any - Predef.u
  Predef.W = Predef.any - Predef.w
  Predef.X = Predef.any - Predef.x
  mcache, fcache, gcache = {}, {}, {}
  local weakmt = {__mode = "v"}
  setmetatable(mcache, weakmt)
  setmetatable(fcache, weakmt)
  setmetatable(gcache, weakmt)
end

lpegrex.updatelocale()

local function make_lpegrex_pattern()
  local l = lpeg
  local lmt = getmetatable(l.P(0))

  local function expect(pattern, label)
    return pattern + l.T(label)
  end

  local function mult(p, n)
    local np = l.P(true)
    while n >= 1 do
      if n % 2 >= 1 then
        np = np * p
      end
      p = p * p
      n = n / 2
    end
    return np
  end

  local function equalcap(s, i, c)
    if type(c) ~= "string" then
      return nil
    end
    local e = #c + i
    if s:sub(i, e - 1) == c then
      return e
    end
    return nil
  end

  local function getdef(id, defs)
    local c = defs and defs[id] or Predef[id]
    if not c then
      error("undefined name: " .. id)
    end
    return c
  end

  local function adddef(t, k, exp)
    if t[k] then
      error("'"..k.."' already defined as a rule")
    else
      t[k] = exp
    end
    return t
  end

  local function firstdef(n, r)
    return adddef({n}, n, r)
  end

  local function NT(n, b)
    if not b then
      error("rule '"..n.."' used outside a grammar")
    end
    return l.V(n)
  end

  local S = (Predef.space + "--" * (Predef.any - Predef.nl)^0)^0
  local Name = l.C(l.R("AZ", "az", "__") * l.R("AZ", "az", "__", "09")^0)
  local Arrow = S * "<-"
  local Num = l.C(l.R"09"^1) * S / tonumber
  local SignedNum = l.C(l.P"-"^-1 * l.R"09"^1) * S / tonumber
  local String = "'" * l.C((Predef.any - "'")^0) * expect("'", "MisTerm1")
               + '"' * l.C((Predef.any - '"')^0) * expect('"', "MisTerm2")
  local Token = "`" * l.C(Predef.punct * (Predef.punct - '`')^0) * expect("`", "MisTerm3")
  local Keyword = "`" * l.C(Predef.alpha * (Predef.any - "`")^0) * expect('`', "MisTerm3")
  local Range = l.Cs(Predef.any * (l.P"-"/"") * (Predef.any - "]")) / l.R
  local Def = Name * l.Carg(1) -- a defined name only have meaning in a given environment
  local Defined = "%" * Def / getdef
  local Item = (Defined + Range + l.C(Predef.any)) / l.P
  local Class =
      "["
    * (l.C(l.P"^"^-1)) -- optional complement symbol
    * l.Cf(expect(Item, "ExpItem") * (Item - "]")^0, lmt.__add)
      / function(c, p) return c == "^" and Predef.any - p or p end
    * expect("]", "MisClose8")

  -- match a name and return a group of its corresponding definition
  -- and 'f' (to be folded in 'Suffix')
  local function defwithfunc(f)
    return l.Cg(Def / getdef * l.Cc(f))
  end

  local exp = l.P{ "Exp",
    Exp = S * ( l.V"Grammar"
                + l.Cf(l.V"Seq" * (S * "/" * expect(S * l.V"Seq", "ExpPatt1"))^0, lmt.__add) );
    Seq = l.Cf(l.Cc(l.P"") * l.V"Prefix" * (S * l.V"Prefix")^0, lmt.__mul);
    Prefix = "&" * expect(S * l.V"Prefix", "ExpPatt2") / lmt.__len
           + "!" * expect(S * l.V"Prefix", "ExpPatt3") / lmt.__unm
           + l.V"Suffix";
    Suffix = l.Cf(l.V"Primary" *
            ( S * ( l.P"+" * l.Cc(1, lmt.__pow)
                  + l.P"*" * l.Cc(0, lmt.__pow)
                  + l.P"?" * l.Cc(-1, lmt.__pow)
                  + "^" * expect( l.Cg(Num * l.Cc(mult))
                                + l.Cg(l.C(l.S"+-" * l.R"09"^1) * l.Cc(lmt.__pow)
                                + Name * l.Cc"lab"
                                ),
                            "ExpNumName")
                  + "->" * expect(S * ( l.Cg((String + Num) * l.Cc(lmt.__div))
                                      + l.P"{}" * l.Cc(nil, l.Ct)
                                      + defwithfunc(lmt.__div)
                                      ),
                             "ExpCap")
                  + "=>" * expect(S * defwithfunc(l.Cmt),
                             "ExpName1")
                  + "~>" * S * defwithfunc(l.Cf)
                  ) --* S
            )^0, function(a,b,f) if f == "lab" then return a + l.T(b) end return f(a,b) end );
    Primary = "(" * expect(l.V"Exp", "ExpPatt4") * expect(S * ")", "MisClose1")
            + String / l.P
            + Token / function(s) return l.P(s) * l.V("SKIP") end
            + Keyword / function(s) return l.P(s) * l.V("SKIP") end
            + Class
            + Defined
            + "%" * expect(l.P"{", "ExpNameOrLab")
              * expect(S * l.V"Label", "ExpLab1")
              * expect(S * "}", "MisClose7") / l.T
            + "{:" * (Name * ":" + l.Cc(nil)) * expect(l.V"Exp", "ExpPatt5")
              * expect(S * ":}", "MisClose2")
              / function(n, p) return l.Cg(p, n) end
            + "=" * expect(Name, "ExpName2")
              / function(n) return l.Cmt(l.Cb(n), equalcap) end
            + l.P"{}" / l.Cp
            + l.P"$" *  ( l.P"nil" / function() return l.Cc(nil) end
                        + l.P"false" / function() return l.Cc(false) end
                        + l.P"true" / function() return l.Cc(true) end
                        + SignedNum / function(s) return l.Cc(tonumber(s)) end
                        + String / function(s) return l.Cc(s) end
                        + (Def / getdef) / l.Cc)
            + l.P"@" *  ( String / function(s) return l.P(s) + l.T('ExpectedString_'..s) end
                        + Name * l.Cb("G") / function(n, b) return NT(n, b) + l.T('Expected_'..n) end)
            + "{~" * expect(l.V"Exp", "ExpPatt6")
              * expect(S * "~}", "MisClose3") / l.Cs
            + "{|" * expect(l.V"Exp", "ExpPatt7")
              * expect(S * "|}", "MisClose4") / l.Ct
            + "{" * expect(l.V"Exp", "ExpPattOrClose")
              * expect(S * "}", "MisClose5") / l.C
            + l.P"." * l.Cc(Predef.any)
            + (Name * -Arrow + "<" * expect(Name, "ExpName3")
               * expect(">", "MisClose6")) * l.Cb("G") / NT;
    Label = Num + Name;
    Definition = Name * Arrow * expect(l.V"Exp", "ExpPatt8");
    Grammar = l.Cg(l.Cc(true), "G")
              * l.Cf(l.V"Definition" / firstdef * (S * l.Cg(l.V"Definition"))^0,
                  adddef) / l.P;
  }

  return S * l.Cg(l.Cc(false), "G") * expect(exp, "NoPatt") / l.P
           * S * expect(-Predef.any, "ExtraChars")
end


local lpegrex_pattern = make_lpegrex_pattern()

--[[
Compiles the given `pattern` string and returns an equivalent LPeg pattern.

The given string may define either an expression or a grammar.
The optional `defs` table provides extra Lua values to be used by the pattern.
]]
function lpegrex.compile(pattern, defs)
  if lpeg.type(pattern) == 'pattern' then -- already compiled
    return pattern
  end
  local cp, label, pos = lpegrex_pattern:match(pattern, 1, defs)
  if not cp then
    -- TODO: show syntax errors
    error("incorrect pattern " .. label, 3)
  end
  return cp
end

--[[
Matches the given `pattern` against the `subject` string.

If the match succeeds, returns the index in the `subject` of the first character after the match,
or the captured values (if the pattern captured any value).

An optional numeric argument `init` makes the match start at that position in the subject string.
]]
function lpegrex.match(subject, pattern, init)
  local cp = mcache[pattern]
  if not cp then
    cp = lpegrex.compile(pattern)
    mcache[pattern] = cp
  end
  return cp:match(subject, init or 1)
end

--[[
Searches the given `pattern` in the given `subject`.

If it finds a match, returns the index where this occurrence starts and the index where it ends.
Otherwise, returns nil.

An optional numeric argument `init` makes the search starts at that position in the `subject` string.
]]
function lpegrex.find(subject, pattern, init)
 local cp = fcache[pattern]
  if not cp then
    cp = lpegrex.compile(pattern)
    cp = cp / 0
    cp = lpeg.P{lpeg.Cp() * cp * lpeg.Cp() + 1 * lpeg.V(1)}
    fcache[pattern] = cp
  end
  local i, e = cp:match(subject, init or 1)
  if i then
    return i, e - 1
  else
    return i
  end
end

--[[
Does a global substitution,
replacing all occurrences of `pattern` in the given `subject` by `replacement`.
]]
function lpegrex.gsub(subject, pattern, replacement)
  local cache = gcache[pattern] or {}
  gcache[pattern] = cache
  local cp = cache[replacement]
  if not cp then
    cp = lpegrex.compile(pattern)
    cp = lpeg.Cs((cp / replacement + 1)^0)
    cache[replacement] = cp
  end
  return cp:match(subject)
end

return lpegrex

--[[
The MIT License (MIT)

Copyright (c) 2021 Eduardo Bart
Copyright (c) 2014-2020 Sérgio Medeiros
Copyright (c) 2007-2019 Lua.org, PUC-Rio.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
