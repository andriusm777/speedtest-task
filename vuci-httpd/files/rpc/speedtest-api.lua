local cURL = require "cURL"
-- pagal viska tai sito nereikia
local speedtest = require "speedtest-dev"

local M = {}

function M.startLocationDetermine()
  os.execute("lua /usr/bin/speedtest --get-location &")
end

function M.getLocation()
  local fileLocationData = '/tmp/locationData.json'
  local file = io.open(fileLocationData, 'r')

  if file == nil then
      speedtest.getLocation() 
  else 
      io.close(file)
  end

  -- -- Here we read each line in a file and add the read lines to our
  -- -- lines empty table
  local lines = {}
  for line in io.lines(fileLocationData) do
    table.insert(lines, line)
  --   -- lines[#lines + 1] = line
  end

  return { data = table.concat(lines) }
end

function M.connectionStatus(params)
  local status, responseCode = pcall(speedtest.connectionStatus, params.server)
  if status == true and responseCode == 200 then
    return { connected = true }
  else
    return { connected = false }
  end
end

return M