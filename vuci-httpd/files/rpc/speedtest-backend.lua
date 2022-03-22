local cURL = require "cURL"
local argparse = require "argparse"

local parser = argparse('speedtest-cli', 'Speedtest command line interface')

local get_server_list = parser:command('get_server_list', 'Gets all active servers and creates a json file of them in the /tmp/allServers.json directory')

local get_location = parser:command('get_location', 'Get location data and write it to /tmp/locationData.json')

local find_servers = parser:command("find_servers", "By default selects optimal server from /tmp/filtered_servers file if the file exists")
find_servers:option("-s --server", "Measures specified server\'s latency")

local find_best_server = parser:command('find_best_server', 'Gets the most performant server from the filtered server list of working servers')

local apiToken = 'TOKEN'

local args = parser:parse()
-- lua /usr/bin/speedtest-backend get_server_list

local TOTAL_TEST_TIME = 10
local MAX_RETRIES = 20
local SIZE = 1000
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
  cURL.easy {
    url = string.format('api.ipstack.com/check?access_key=%s', apiToken),
    writefunction = file
  }
  :perform()
  :close()
  file:close()
end

function Find_servers()
  -- if args.count ~= nil and tonumber(args.count) < 
  local f = io.open("/dev/null", "w")
  if args.server ~= nil then
      local results = io.open("/tmp/findServers", "a")
      local status, _, responseCode, total_time = pcall(Measure_latency, f, args.server)
      -- if not args.quiet then
      --     print(string.format("%-35s %-15s %-8s", "Server", "Response_code", "Total_time")) 
      -- end
      if status then
          results:write(args.server .. "," .. responseCode .. "," .. total_time .. "\n")
          -- if not args.quiet then
          --     print(string.format("%-35s %-15s %-8s", args.server, code, total_time))
          -- end
      else
          results:write(args.server .. "," .. 500 .. "," .. -1 .. "\n")
          -- if not args.quiet then
          --     print(string.format("%-35s %-15s %-8s", args.server, 500, -1))
          -- end
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

if args.find_servers then Find_servers() end
if args.find_best_server then Find_best_server() end

if args.get_server_list then GetServers() end
if args.get_location then GetLocation() end