local cURL = require "cURL"

local USERAGENT = 'libcurl-speedchecker/1.0'
local M = {}

-- function M.getServers()
--   local file = io.open('/tmp/serversList.json', 'w')
--   cURL.easy{
--     url = 'https://server-list.azurewebsites.net/available/',
--     writefunction = file
--   }
--   :perform()
--   :close()
--   file:close()
-- end

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

-- function M.getLocation()
--   -- local data = {}
--   local file = io.open('/tmp/locationData.json', 'w')
--   -- file:write("test" .. "/n")
--   cURL.easy {
--     url = string.format('ipinfo.io?token=%s', apiToken),
--     writefunction = file
--   }
--   :perform()
--   :close()
--   file:close()
-- end

-- function M.getLocation()
--   local table = {}
--   cURL.easy {
--     url = string.format('http://api.ipstack.com/check?access_key=%s', apiToken),
--     writefunction = table
--   }
--   :perform()
--   :close()
--   print('does this work')
--   for _, v in pairs(table) do
--     print(v)
--   end
--   return { data = table }
-- end


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


-- if arg == "get-location"
--   M.getLocation()
-- elseif arg == "determine-server" then
--   -- do other function
-- end
return M

