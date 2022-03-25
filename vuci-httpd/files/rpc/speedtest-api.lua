local cURL = require "cURL"
local speedtest = require "speedtest-dev"

local M = {}

function M.get_location_data()
  local fileLocationData = '/tmp/locationData.json'
  local file = io.open(fileLocationData, 'r')

  if file == nil then
      os.execute("lua /usr/bin/speedtest-backend get_location")
  end

  local lines = {}
  for line in io.lines(fileLocationData) do
    table.insert(lines, line)
  end
  return { data = lines, message = 'idk' }


  -- local fileLocationData = '/tmp/locationData.json'
  -- local file = io.open(fileLocationData, 'r')

  -- if file == nil then
  --     speedtest.getLocation()
  -- else
  --     io.close(file)
  -- end
  -- -- -- Here we read each line in a file and add the read lines to our
  -- -- -- lines empty table
  -- local lines = {}
  -- for line in io.lines(fileLocationData) do
  --   table.insert(lines, line)
  -- --   -- lines[#lines + 1] = line
  -- end

  -- return { data = lines }
end

-- function M.get_location_data()
--   -- local status, table = pcall(speedtest.getLocation)
--   -- if status == true then
--   --   return { data = table }
--   -- else
--   --   return { data = 'something went wrong' }
--   -- end

--   local table = {}
--   local c = cURL.easy {
--     url = string.format('http://api.ipstack.com/check?access_key=%s', apiToken)
--   }
--   c:setopt_writefunction(table.insert, table)
--   c:perform()
--   c:close()
--   return { data = 'ddd'}
--   -- return { data = table.concat(table) }
--   -- :perform()
--   -- :close()
--   -- print('does this work')
--   -- for _, v in pairs(table) do
--   --   print(v)
--   -- end
--   -- return { data = table }
-- end

function M.testas()
  local lel = 'vienas'
  return { connected = true }
end

function M.check_connection_status(params)
  local status, responseCode = pcall(speedtest.connectionStatus, params.server)
  if status == true and responseCode == 200 then
    return { connected = true }
  else
    return { connected = false }
  end
end

function M.get_all_servers()
  local allServersFile = '/tmp/allServers.json'
  local file = io.open(allServersFile, 'r')

  if file == nil then
    os.execute('lua /usr/bin/speedtest-backend get_server_list')
  else
    io.close(file)
  end

  local lines = {}

  for line in io.lines(allServersFile) do
    table.insert(lines, line)
  end

  return { data = table.concat(lines) }
end

function M.init_best_server_search()
  local results_filename = "/tmp/findServers"
  local results_file = io.open(results_filename, "r")
  if results_file == nil then
    return { message = "No results file found yet"}
  end
  os.execute("lua /usr/bin/speedtest-backend find_best_server &")
  return { message = true }
end

function M.find_servers(params)
  os.remove("/tmp/findServers")

  local results = io.open("/tmp/findServers", "a")
  -- results:write(table.getn(params.servers) .. "\n")
  io.close(results)
  for _, v in pairs(params.servers) do
      os.execute("lua /usr/bin/speedtest-backend find_servers -s " .. v.host .. " &")
  end

  return { message = "Best server search started" }
end

function M.get_best_server()
  local best_filename = "/tmp/bestServers"
  local best_file = io.open(best_filename, "r")
  if best_file ~= nil then
    io.close(best_file)
    local lines = {}
    for line in io.lines(best_filename) do
      table.insert(lines, line)
    end
    return { data = lines, message = 'Selected fastest server' }
  end
end

function M.start_download(params)
  os.remove("/tmp/downloadResult")
  local download_result = "/tmp/downloadResult"
  local download_result_file = io.open(download_result, "r")
  if download_result_file == nil then
    -- io.close(download_result_file)
    os.execute("lua /usr/bin/speedtest-backend start_download -s " .. params.server .. " &")
    return { message = 'Download test started' }
  else
    return
  end
end

function M.get_download_results()
  local download_result = "/tmp/downloadResult"
  local download_result_file = io.open(download_result, "r")
  if download_result_file ~= nil then
    io.close(download_result_file)
    local lines = {}
    for line in io.lines(download_result) do
      table.insert(lines, line)
    end
    return { data = lines, message = 'Finished download test'}
    else
      return { message = "Download result data not yet created"}
  end
end

return M