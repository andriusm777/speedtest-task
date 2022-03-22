local cURL = require "cURL"
local speedtest = require "speedtest-dev"

local M = {}

function M.get_location_data()
  local fileLocationData = '/tmp/locationData.json'
  local file = io.open(fileLocationData, 'r')

  if file == nil then
      os.execute('lua /usr/bin/speedtest-backend get_location')
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

  return { data = lines }
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
  -- minus nes nenorim kad pirma linija uzsiskaitytu kaip perskaityta linija
  -- local count = -1
  -- for _ in io.lines(results_filename) do
  --   count = count + 1
  -- end
  -- palyginam ar pirma linija(servu skaicius) lygi DABAR perskaitytu servu skaiciui
  -- if tonumber(results_file:read()) == count then
  --   os.execute('lua /usr/bin/speedtest-backend find_best_server &')
  --   return { message = true }
  -- end
  -- local countFound = tonumber(results_file:read())
  -- io.close(results_file)
  -- return { message = false, counted = count, countFound = countFound }

  os.execute("lua /usr/bin/speedtest-backend find_best_server &")
  return { message = true }
end

function M.find_servers(params)
  os.remove("/tmp/findServers")
  
  local results = io.open("/tmp/findServers", "a")
  results:write(table.getn(params.servers) .. "\n")
  
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

return M