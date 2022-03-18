local cURL = require "cURL"

local apiToken = 'de91c515e1533c'
local USERAGENT = 'libcurl-speedchecker/1.0'
local M = {}

function M.getLocation()
  -- local data = {}
  local file = io.open('/tmp/locationData.json', 'w')
  -- file:write("test" .. "/n")
  cURL.easy {
    url = string.format('ipinfo.io?token=%s', apiToken),
    writefunction = file
  }
  :perform()
  :close()
  file:close()
end

function M.getServers()
  local file = io.open('/tmp/serversList.json', 'w')
  cURL.easy{
    url = 'https://server-list.azurewebsites.net/available/',
    writefunction = file
  }
  :perform()
  :close()
  file:close()
end

function M.connectionStatus(server)
  local curl = cURL.easy {
    url = server,
    useragent = USERAGENT,
    timeout = 5
  }
  curl:perform()
  local responseCode = curl:getinfo_response_code()
  curl:close()
  return responseCode
end


-- if arg == "get-location"
--   M.getLocation()
-- elseif arg == "determine-server" then
--   -- do other function
-- end
return M