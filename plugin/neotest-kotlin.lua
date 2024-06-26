local exists = require("neotest.lib.file").exists
local job = require("plenary.job")
local logger = require("neotest.logging")
local lib = require("neotest.lib")

local options = {
  setup = function()
    local filepath = vim.fn.stdpath("data") .. "/neotest-kotlin/junit-platform-console-standalone-1.10.1.jar"
    if exists(filepath) then
      lib.notify("Already setup!")
      return
    end

    -- Download Junit Standalone Jar
    local stderr = {}
    job
      :new({
        command = "curl",
        args = {
          "--output",
          filepath,
          "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar",
          "--create-dirs",
        },
        on_stderr = function(_, data)
          table.insert(stderr, data)
        end,
        on_exit = function(_, code)
          if code == 0 then
            lib.notify("Downloaded Junit Standalone successfully!")
          else
            local output = table.concat(stderr, "\n")
            lib.notify(string.format("Error while downloading: \n %s", output), "error")
            logger.error(output)
          end
        end,
      })
      :start()
  end,
}

vim.api.nvim_create_user_command("NeotestKotlin", function(info)
  local fun = options[info.args] or error("Invalid option")
  fun()
end, {
  desc = "Setup neotest-kotlin",
  nargs = 1,
  complete = function()
    -- keys from options
    return vim.tbl_keys(options)
  end,
})
