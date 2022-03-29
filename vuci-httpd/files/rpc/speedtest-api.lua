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
  os.execute("lua /usr/bin/speedtest-backend start_download -s " .. params.server .. " &")
  return { message = 'Download test started', hasStarted = true }
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
    return { data = lines }
    else
      return { message = "Download result data not yet created"}
  end
end

function M.start_upload(params)
  os.remove("/tmp/uploadResult")
  os.execute("lua /usr/bin/speedtest-backend start_upload -s " .. params.server .. " &")
  return { message = 'Upload test started', hasStarted = true }
end

function M.get_upload_results()
  local upload_result = "/tmp/uploadResult"
  local upload_result_file = io.open(upload_result, "r")
  if upload_result_file ~= nil then
    io.close(upload_result_file)
    local lines = {}
    for line in io.lines(upload_result) do
      table.insert(lines, line)
    end
    return { data = lines }
    else
      return { message = "Upload result data not yet created"}
  end
end

return M