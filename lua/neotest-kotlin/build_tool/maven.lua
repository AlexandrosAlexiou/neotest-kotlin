local Path = require("plenary.path")
local scan = require("plenary.scandir")
local run = require("neotest-kotlin.command.run")
local read_xml_tag = require("neotest-kotlin.util.read_xml_tag")
local mvn = require("neotest-kotlin.command.binaries").mvn
local logger = require("neotest.logging")

local memoized_result

--@class neotest-kotlin.BuildTool
local maven = {}

maven.source_directory = function()
  return "src/main/kotlin"
end

maven.test_source_directory = function()
  local tag_content = read_xml_tag("pom.xml", "project.build.testSourceDirectory")
  if tag_content then
    logger.debug("Found testSourceDirectory in pom.xml: " .. tag_content)
    return tag_content
  end
  return "src/test/kotlin"
end

maven.get_output_dir = function()
  -- TODO: read from pom.xml <build><directory>
  return "target/neotest-kotlin"
end

maven.get_sources_glob = function()
  -- TODO: read from pom.xml <sourceDirectory>

  -- check if there are generated sources
  local generated_sources = scan.scan_dir("target", {
    search_pattern = ".+%.kt",
  })
  if #generated_sources > 0 then
    return ("%s/**/*.kt target/**/*.kt"):format(maven.source_directory())
  end
  return ("%s/**/*.kt"):format(maven.source_directory())
end

maven.get_test_sources_glob = function()
  -- TODO: read from pom.xml <testSourceDirectory>
  return "src/test/**/*.kt"
end

maven.get_resources = function()
  -- TODO: read from pom.xml <resources>
  return { "src/main/resources", "src/test/resources" }
end

--@return string
maven.get_jvm_target = function()
  local jvm_target = read_xml_tag("pom.xml", "project.properties.java.version")
  return jvm_target or "21"
end

---@return string
maven.get_dependencies_classpath = function()
  if memoized_result then
    return memoized_result
  end

  local command = mvn() .. " -q dependency:build-classpath -Dmdep.outputFile=target/neotest-kotlin/classpath.txt"
  run(command)

  local classpath_file = "target/neotest-kotlin/classpath.txt"
  if not Path:new(classpath_file):exists() then
    error("Classpath file not found: " .. classpath_file)
  end

  local dependency_classpath = ""
  for line in io.lines(classpath_file) do
    dependency_classpath = dependency_classpath .. line
  end

  if string.match(dependency_classpath, "ERROR") then
    error('error while running command "' .. command .. '" -> ' .. dependency_classpath)
  end

  memoized_result = dependency_classpath
  return dependency_classpath
end

maven.write_classpath = function(filepath)
  local classpath = maven.get_dependencies_classpath()

  -- create folder if not exists
  run("mkdir -p " .. filepath:match("(.+)/[^/]+"))

  -- remove file if exists
  run("rm -f " .. filepath)

  -- write in file per buffer of 500 characters
  local file = io.open(filepath, "w") or error("Could not open file for writing: " .. filepath)
  local buffer = ""
  for i = 1, #classpath do
    buffer = buffer .. classpath:sub(i, i)
    if i % 500 == 0 then
      file:write(buffer)
      buffer = ""
    end
  end
  -- write the remaining buffer
  if buffer ~= "" then
    file:write(buffer)
  end

  file:close()
end

return maven
