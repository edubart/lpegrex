-- Used as an input example for the Lua parser.
local function fact(n)
  if n == 0 then
    return 1
  else
    return n * fact(n-1)
  end
end
print(fact(10))
