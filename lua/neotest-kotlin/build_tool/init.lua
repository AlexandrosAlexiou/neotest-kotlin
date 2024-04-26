local maven = require("neotest-kotlin.build_tool.maven")
local gradle = require("neotest-kotlin.build_tool.gradle")

---@class neotest-kotlin.BuildTool
---@field get_dependencies_classpath fun(): string
---@field get_output_dir fun(): string
---@field write_classpath fun(classpath_filepath: string) writes the classpath into a file
---@field get_sources_glob fun(): string
---@field source_dir fun(): string
---@field get_test_sources_glob fun(): string
---@field get_resources fun(): string[]
local BuildTool = {}

local build_tools = {}

--- will determine the build tool to use
---@return neotest-kotlin.BuildTool
build_tools.get = function(project_type)
  if project_type == "gradle" then
    return gradle
  elseif project_type == "maven" then
    return maven
  end
  error("unknown project type: " .. project_type)
end

return build_tools
