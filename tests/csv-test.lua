local parse_csv = require 'parsers.csv'
local lester = require 'tests.lester'

local describe, it, expect = lester.describe, lester.it, lester.expect

describe("csv", function()

it("simple", function()
  local source = [[name,age
John,20
Maria,23]]
  local expected_csv = {
    {'name', 'age'},
    {'John', 20},
    {'Maria', 23},
  }
  expect.equal(parse_csv(source), expected_csv)
end)

it("quoted strings", function()
  local source = [[name,age
"John",20
"Maria "" Maria
Maria",23
Paul "Paul",24]]
  local expected_csv = {
    {'name', 'age'},
    {'John', 20},
    {'Maria " Maria\nMaria', 23},
    {'Paul "Paul"', 24},
  }
  expect.equal(parse_csv(source), expected_csv)
end)

it("complex", function()
  local source = [[Year,Make,Model,Description,Price
1997,Ford,E350,"ac, abs, moon",3000.00
1999,Chevy,"Venture ""Extended Edition""","",4900.00
1999,Chevy,"Venture ""Extended Edition, Very Large""",,5000.00
1996,Jeep,Grand Cherokee,"MUST SELL!
air, moon roof, loaded",4799.00]]
  local expected_csv = {
    { 'Year', 'Make', 'Model', 'Description', 'Price' },
    { 1997, 'Ford', 'E350', 'ac, abs, moon', 3000.0 },
    { 1999, 'Chevy', 'Venture "Extended Edition"', '', 4900.0 },
    { 1999, 'Chevy', 'Venture "Extended Edition, Very Large"', '', 5000.0 },
    { 1996, 'Jeep', 'Grand Cherokee', 'MUST SELL!\nair, moon roof, loaded', 4799.0 }
  }
  expect.equal(parse_csv(source), expected_csv)
end)

end)
