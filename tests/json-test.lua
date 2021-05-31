local parse_json = require 'parsers.json'
local lester = require 'tests.lester'

local describe, it, expect = lester.describe, lester.it, lester.expect

describe("json", function()

it("simple", function()
  local source = '[{"string":"some\\ntext", "boolean":true, "number":-1.5e+2, "null":null}]'
  local expected_json =
  { tag = "Array", pos = 1, endpos = 73,
    { tag = "Object", pos = 2, endpos = 72,
      { tag = "Member", pos = 3, endpos = 24,
      "string","some\ntext" },
      { tag = "Member", pos = 26, endpos = 40,
      "boolean", true },
      { tag = "Member", pos = 42, endpos = 58,
        "number", -150.0 },
      { tag = "Member", pos = 60, endpos = 71,
        "null", nil }
    }
  }
  expect.equal(parse_json(source), expected_json)
end)

end)
