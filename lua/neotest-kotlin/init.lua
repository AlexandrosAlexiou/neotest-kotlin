---@diagnostic disable: undefined-doc-name, duplicate-doc-field, duplicate-set-field

local File = require("neotest.lib.file")

local file_checker = require("neotest-kotlin.core.file_checker")
local root_finder = require("neotest-kotlin.core.root_finder")
local dir_filter = require("neotest-kotlin.core.dir_filter")
local position_discoverer = require("neotest-kotlin.core.positions_discoverer")
local spec_builder = require("neotest-kotlin.core.spec_builder")
local result_builder = require("neotest-kotlin.core.result_builder")

local detect_project_type = require("neotest-kotlin.util.detect_project_type")
local there_is_wrapper_in = require("neotest-kotlin.util.there_is_wrapper_in")

local check_junit_jar = function(filepath)
  local exists, _ = File.exists(filepath)
  assert(
    exists,
    ([[
    Junit Platform Console Standalone jar not found at %s
    Please run the following command to download it: NeotestKotlin setup
    Or alternatively, download it from https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar
  ]]):format(filepath)
  )
end

---@class neotest.Adapter
NeotestKotlinAdapter = {
  name = "neotest-kotlin",
  project_type = "maven", -- default to maven
  config = {
    ignore_wrapper = false,
    junit_jar = vim.fn.stdpath("data") .. "/neotest-kotlin/junit-platform-console-standalone-1.10.1.jar",
  },
}

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function NeotestKotlinAdapter.root(dir)
  return root_finder.find_root(dir)
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function NeotestKotlinAdapter.filter_dir(name, rel_path, root)
  return dir_filter.filter_dir(name, rel_path, root)
end

---@async
---@param file_path string
---@return boolean
function NeotestKotlinAdapter.is_test_file(file_path)
  return file_checker.isTestFile(file_path)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function NeotestKotlinAdapter.discover_positions(file_path)
  return position_discoverer.discover_positions(file_path)
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function NeotestKotlinAdapter.build_spec(args)
  local self = NeotestKotlinAdapter
  check_junit_jar(self.config.junit_jar)

  -- TODO: find a way to avoid to make this steps every time

  -- find root
  ---@diagnostic disable-next-line: undefined-field
  local root = self.root(args.tree:data().path)

  -- detect project type
  ---@diagnostic disable-next-line: inject-field, param-type-mismatch
  self.project_type = detect_project_type(root)

  -- decide to ignore wrapper or not
  local ignore_wrapper = self.config.ignore_wrapper
  if not ignore_wrapper then
    ---@diagnostic disable-next-line: param-type-mismatch
    ignore_wrapper = not there_is_wrapper_in(root)
  end

  -- build spec
  local res = spec_builder.build_spec(args, self.project_type, ignore_wrapper, self.config)
  return res
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function NeotestKotlinAdapter.results(spec, result, tree)
  return result_builder.build_results(spec, result, tree)
end

-- on init
(function()
  -- create data directory if it doesn't exist
  local data_dir = vim.fn.stdpath("data") .. "/neotest-kotlin"
  os.execute("mkdir -p " .. data_dir)
end)()

setmetatable(NeotestKotlinAdapter, {
  __call = function(_, opts)
    opts = opts or {}
    local config = NeotestKotlinAdapter.config or {}
    NeotestKotlinAdapter.config = vim.tbl_extend("force", config, opts)
    return NeotestKotlinAdapter
  end,
})

return NeotestKotlinAdapter
