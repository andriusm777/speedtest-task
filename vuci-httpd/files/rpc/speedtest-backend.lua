local cURL = require "cURL"
local argparse = require "argparse"
local socket = require "socket"
local os = require "os"

local parser = argparse('speedtest-cli', 'Speedtest command line interface')

local get_server_list = parser:command('get_server_list', 'Gets all active servers and creates a json file of them in the /tmp/allServers.json directory')

local get_location = parser:command('get_location', 'Get location data and write it to /tmp/locationData.json')

local find_servers = parser:command("find_servers", "Checks given servers status code(if its a 200 or 500 status code) and the latency of it and prints the output to /tmp/findServers")
find_servers:option("-s --server", "Checks servers response code and latency and prints it to a file")

local find_best_server = parser:command('find_best_server', 'Gets the most performant server from the filtered server list of working servers')

local start_download = parser:command("start_download", "Starts a download test and writes the results to /tmp/downloadResult")
start_download:option("-s --server", "Performs download test with the given server")

local start_upload = parser:command("start_upload", "Starts an upload test and writes the results to /tmp/uploadResult")
start_upload:option("-s --server", "Performs an upload test with the given server")

local apiToken = 'TOKEN'

local args = parser:parse()
-- lua /usr/bin/speedtest-backend get_server_list

local TOTAL_TEST_TIME = 15
local MAX_RETRIES = 20
local SIZE = 100000000
local AGENT = "libcurl-speedchecker/1.0"

function GetServers ()
  local serversFile = io.open('/tmp/allServers.json', 'w')
  cURL.easy {
    url = 'https://server-list.azurewebsites.net/available/',
    writefunction = serversFile
  }
  :perform()
  :close()
  serversFile:close()
end

function GetLocation()
  local file = io.open('/tmp/locationData.json', 'w')
  -- local table = {}
  cURL.easy {
    url = string.format('http://api.ipstack.com/check?access_key=%s', apiToken),
    writefunction = file
  }
  :perform()
  :close()
  -- return table
  file:close()
end

function Find_servers()
  local f = io.open("/dev/null", "w")
  if args.server ~= nil then
      local results = io.open("/tmp/findServers", "a")
      local status, _, responseCode, total_time = pcall(Measure_latency, f, args.server)
      if status then
          results:write(args.server .. "," .. responseCode .. "," .. total_time .. "\n")
      else
          results:write(args.server .. "," .. 500 .. "," .. -1 .. "\n")
      end
      io.close(results)
      return
  end
end

function Write_as_json(filename, params)
  local function write_object(file, T, idx, key_count)
      for k, v in pairs(T) do
          idx = idx + 1
          if type(v) == "number" then
              file:write("\"" .. k .. "\":" .. v .. "")
          else
              file:write("\"" .. k .. "\":\"" .. v .. "\"")
          end
          if idx ~= key_count then
              file:write(",")
          end
      end
  end
  if params == nil then return end
  local size = table.getn(params)
  if size == 0 then return end
  local key_count = Get_key_count(params[1])
  local file = io.open(filename, "w")
  local idx = 0
  file:write("[")
  for key, value in pairs(params) do
      file:write("{")
      write_object(file, value, idx, key_count)
      file:write("}")
      if key ~= size then
          file:write(",")
      end
      idx = 0
  end
  file:write("]\n")
  io.close(file)
end

function Measure_latency(f, server)
  local c = cURL.easy{
      url = server .. "/download?size=10000",
      port = 8080,
      useragent = AGENT,
      writefunction = f,
      timeout = 1
  }
  c:perform()
  local code = c:getinfo_response_code()
  local total_time = c:getinfo_total_time()
  c:close()
  return server, code, total_time
end

function Get_key_count(T)
  local length = 0
  for _, _ in pairs(T) do
      length = length + 1
  end
  return length
end

function Split (inputstr, sep)
  if sep == nil then
      sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
  end
  return t
end

function Find_best_server()
  local filename = "/tmp/findServers"
  local file = io.open(filename, "r")
  if file ~= nil then
      io.close(file)
  else return
  end
  local servers = {}
  local count = 0
  for line in io.lines(filename) do
      count = count + 1
      -- neskaitom pacios pirmos eilutes
      if count > 1 then
          -- vienos eilutes string "vienas,du,trys" atskiria per kableli ir ideda i table { [1]'vienas',[2]'du',[3]'trys' }
          local data = Split(line, ",")
          if data[2] == "200" then
              table.insert(servers, {server = data[1], code = data[2], total_time = data[3]})
          end
      end
  end
  -- su maziausia reiksme gauname paciam virsuj ir galim nusiskaityti su [0] per vue
  table.sort(servers, function (server1, server2) return server1.total_time < server2.total_time end )
  Write_as_json("/tmp/bestServers", servers)
end

function Start_upload()
  os.remove("/tmp/uploadResult")
  local upload_filename = "/dev/zero"
  if args.server ~= nil then
    local full_upload_url = args.server .. "/upload"
    -- GOOD
    local c = cURL.easy {
      url = full_upload_url,
      post = true,
      port = 8080,
      useragent = AGENT,
      httppost = cURL.form {
        file0 = {
          file = upload_filename,
          type = "text/plain",
          name = "fileToUpload.txt",
        }
      }
    }
    local start_time = socket.gettime()
  
    c:setopt_progressfunction(function(_, _, ultotal, ulnow)
      local results_file = io.open("/tmp/uploadResult", "w")
      local end_time = socket.gettime()
      local uploaded_size_MB = ulnow / 1000000
      local total_time = end_time - start_time
      local upload_speed_mb = uploaded_size_MB * 8 / total_time
      local total_size_MB = ultotal / 1000000
      local percent_uploaded = math.floor((ulnow / ultotal * 100) * 100) / 100
      io.write(ulnow .. " " .. args.server .. " " .. total_size_MB .. " " .. uploaded_size_MB .. " " .. percent_uploaded .. " " .. upload_speed_mb .. " " .. total_time .. "\n")

      local out = io.open("/tmp/uploadResult", "r")
      local resultsTable = {}

      for line in out:lines() do
        table.insert(resultsTable, line)
      end

      out:close()
      
      if total_time < TOTAL_TEST_TIME then
        table.insert(resultsTable, 1, 'processing' .. ',' .. upload_speed_mb)
        for _, line in ipairs(resultsTable) do
          results_file:write(line)
        end
        io.close(results_file)
        
      end

      if total_time >= TOTAL_TEST_TIME then
        local results_file = io.open("/tmp/uploadResult", "w")
        table.insert(resultsTable, 1, 'done' .. ',' .. upload_speed_mb)
        for _, line in ipairs(resultsTable) do
          results_file:write(line)
        end
        io.close(results_file)
        return 0
      end
    end)
    c:setopt(cURL.OPT_NOPROGRESS, false)
    local status, error = pcall(function() c:perform() end)
  end
end

function Start_download()
  local download_filename = "/dev/null"
  local download_file = io.open(download_filename, "w")
  if args.server ~= nil then
    local full_download_url = args.server .. "/download?size=" .. SIZE
    local c = cURL.easy {
      url = full_download_url,
      port = 8080,
      useragent = AGENT,
      writefunction = download_file
    }
    local start_time = socket.gettime()
    
    c:setopt_progressfunction(function(dltotal, dlnow)
      local results_file = io.open("/tmp/downloadResult", "w")
      local end_time = socket.gettime()
      local downloaded_size_MB = dlnow / 1000000
      -- local downloaded_size_mb = dlnow / 131.072
      local total_time = end_time - start_time
      -- local download_speed = downloaded_size_mb * 8 / total_time
      local download_speed_mb = downloaded_size_MB * 8 / total_time
      local total_size_MB = dltotal / 1000000
      local percent_downloaded = math.floor((dlnow / dltotal * 100) * 100) / 100
      io.write(dlnow .. " " .. args.server .. " " .. total_size_MB .. " " .. downloaded_size_MB .. " " .. percent_downloaded .. " " .. download_speed_mb .. " " .. total_time .. "\n")
      local out = io.open("/tmp/downloadResult", "r")
      local resultsTable = {}

      for line in out:lines() do
        table.insert(resultsTable, line)
      end

      out:close()
      
      if dlnow < 100000000 and total_time < TOTAL_TEST_TIME then
        table.insert(resultsTable, 1, 'processing' .. ',' .. download_speed_mb)
        for _, line in ipairs(resultsTable) do
          results_file:write(line)
        end
        io.close(results_file)
        
      end

      if dlnow == 100000000 or total_time >= TOTAL_TEST_TIME then
        local results_file = io.open("/tmp/downloadResult", "w")
        table.insert(resultsTable, 1, 'done' .. ',' .. download_speed_mb)
        for _, line in ipairs(resultsTable) do
          results_file:write(line)
        end
        io.close(results_file)
        return 0
      end
    end)
    c:setopt(cURL.OPT_NOPROGRESS, false)
    -- assert(c:perform())
    local status, error = pcall(function() c:perform() end)
    -- print('after setopt_progressfunction')
    -- print(test)
    io.close(download_file)
    -- io.close(results_file)
  end
end

if args.start_download then Start_download() end
if args.start_upload then Start_upload() end

if args.find_servers then Find_servers() end
if args.find_best_server then Find_best_server() end

if args.get_server_list then GetServers() end
if args.get_location then GetLocation() end
