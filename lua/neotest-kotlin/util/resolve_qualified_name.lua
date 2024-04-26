local read_file = require("neotest-kotlin.util.read_file")

local function resolve_qualified_name(filename)
  local function find_in_text(raw_query, content)
    local query = vim.treesitter.query.parse("kotlin", raw_query)

    local lang_tree = vim.treesitter.get_string_parser(content, "kotlin")
    local root = lang_tree:parse()[1]:root()

    local result = ""
    for _, node, _ in query:iter_captures(root, content, 0, -1) do
      result = vim.treesitter.get_node_text(node, content)
      break
    end
    return result
  end

  -- read the file
  local ok, content = pcall(function()
    return read_file(filename)
  end)
  if not ok then
    error(string.format("file does not exist: %s", filename))
  end

  -- get the package name
  local package_query = [[
    ((package_header (identifier) @package.name))
  ]]

  -- get the class name
  local class_name_query = [[
    ((class_declaration (type_identifier) @target))
  ]]

  local package_line = find_in_text(package_query, content)
  local name = find_in_text(class_name_query, content)

  return package_line .. "." .. name
end

return resolve_qualified_name
