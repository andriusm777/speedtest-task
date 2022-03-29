local cURL = require "cURL"

local USERAGENT = 'libcurl-speedchecker/1.0'
local M = {}

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

return M

