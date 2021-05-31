local astutil = {}

local function _ast2string(node, indent, ss)
  if node.tag then
    ss[#ss+1] = indent..node.tag
  else
    ss[#ss+1] = indent..'-'
  end
  indent = indent..'| '
  for i=1,#node do
    local child = node[i]
    local ty = type(child)
    if ty == 'table' then
      _ast2string(child, indent, ss)
    elseif ty == 'string' then
      local escaped = child
        :gsub([[\]], [[\\]])
        :gsub([[(['"])]], [[\%1]])
        :gsub('\n', '\\n'):gsub('\t', '\\t')
        :gsub('[^ %w%p]', function(s)
          return string.format('\\x%02x', string.byte(s))
        end)
      ss[#ss+1] = indent..'"'..escaped..'"'
    else
      ss[#ss+1] = indent..tostring(child)
    end
  end
end

-- Convert an AST into a human readable string.
function astutil.ast2string(node)
  local ss = {}
  _ast2string(node, '', ss)
  return table.concat(ss, '\n')
end

return astutil
