LUA=lua

test:
	$(LUA) tests/test.lua
	$(LUA) examples/json-ast.lua inputs/sample.json
	$(LUA) examples/lua-ast.lua inputs/fact.lua
	$(LUA) examples/c11-ast.lua inputs/fact.c
