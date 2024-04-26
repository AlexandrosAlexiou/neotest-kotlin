local lib = require("neotest.lib")

PositionsDiscoverer = {}

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function PositionsDiscoverer.discover_positions(file_path)
  local query = [[
        ;; Test class
        (
            class_declaration
            (type_identifier) @type_identifier
        ) @namespace.definition

        ;; @Test and @ParameterizedTest functions
        (
            function_declaration
            (modifiers
                (annotation
                    (user_type) @type_identifier
                    (#any-of? @type_identifier "Test" "ParameterizedTest")
                )
            )
            (simple_identifier) @test.name
        ) @test.definition
    ]]

  return lib.treesitter.parse_positions(file_path, query, { nested_namespaces = true })
end

return PositionsDiscoverer
