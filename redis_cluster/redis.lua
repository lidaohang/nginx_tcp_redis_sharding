local require,pairs = require,pairs
local setmetatable = setmetatable

local ngx_util=require "ngx_util"
local manage=require "manage.lua"
 
module(...)

_VERSION = '0.1'

--[[request socket]]
function get_req_socket()
	local req = ngx.req.socket()   
	req:settimeout(1000)
	return req
end

function get_req_socket_receive(req_socket)
	local rt, err = req_socket:receive()
	if not rt then
        ngx_util.error_log("redis.lua		failed to recv req: ".. err)
        return nil
    end
	 
	local r = rt:byte(1,1)
	cnt = 0
	ngx_util.debug_log("redis.lua		receive  r "..r)
	if r == 42 then    -- 42(*) 返回多个块数据
		cnt = tonumber(rt:sub(2))
	else
		ngx_util.error_log("redis.lua		read a non * line")	--数据格式错误
		cnt = 0
	end
	
	buf = rt.."\r\n"
	local i = 1
	ngx_util.debug_log("redis.lua		rt "..rt)
	while i <= cnt * 2 do		--构建接收到数据格式
		rt, err = req_socket:receive()
		if not rt then
			ngx_util.error_log("redis.lua		failed to recv req: " .. err)
			return nil
		end
		buf = buf..rt.."\r\n"
		i = i + 1
	end
    return buf
end




--[[redis socket]]
function create_redis_socket()
	local serversocket=ngx.socket.tcp()  
	return serversocket
end

--get data redis key
local function get_data_key(data)
	local findStr=ngx_util.split_string(data,"$")
	local count=0
	local num=0
	for k,v in pairs(findStr) do
		count=count+1
		if count == 3 then
			num=0
			for j,m in pairs(splitStr(v,"\r\n")) do
				num=num+1
				if num == 2 then
					return m
				end
			end
		end
	end
end	


local function get_redis_server(data)
	
	local key=get_data_key(data)
	ngx_util.debug_log("redis.lua		consistent_hash key "..key)
	
	local ipserver = manage.consistent_hash(key)
	ngx_util.debug_log("redis.lua		consistent_hash ipserver"..ipserver)
	
	local ip=string.sub(ipserver,1,string.find(ipserver,":")-1)
	local port=string.sub(ipserver,string.find(ipserver,":")+1,string.len(ipserver))
	
	return ip,port
end



function get_redis_socket()
	--get server
	local ip,port=get_redis_server(buf)
	
	local server_socket=create_redis_socket()
	local rt, err = server_socket:connect(ip, tonumber(port))
	if not rt then
		ngx_util.error_log("redis.lua		failed to connect: ", err)
		return nil
	end
	return server_socket
end



function get_redis_socket_receive(redis_socket)
	local rt, err = redis_socket:receive()
	if not rt then
		ngx_util.error_log("redis.lua		failed to recv first resp: " .. err)
		return nil
	end
		
	local r = rt:byte(1,1)
	local cnt = 0
	local buf = rt.."\r\n"
	ngx_util.debug_log("redis.lua		succeed to upsock:receive buf "..buf)
	
	ngx_util.debug_log("redis.lua		succeed to upsock:receive r "..r)
	if r == 36 then  -- $返回响应的数据块
		ngx_util.debug_log("redis.lua		upsock:receive buf  " .. buf)
		rt, err = redis_socket:receive()
		if not rt then
			ngx_util.debug_log("redis.lua		failed to recv single resp: " .. err)
			return nil
		end
		buf = buf..rt.."\r\n"
	--elseif r == 45 or r == 43 or r == 58 then  -- 45(-)代表发送了错误   43(+)代表一个状态信息如 +ok  58(:)返回的是一个整数  格式如：":11\r\n
	--	ngx_util.debug_log("succeed to upsock:receive (45-,43+) r "..r)
	elseif  r == 42 then    -- *返回多个块数据
		cnt = tonumber(rt:sub(2))
	end
			
	local i = 1
	while i <= cnt * 2 do
		rt, err = redis_socket:receive()
		if not rt then
			ngx.log(ngx.ERR, "redis.lua		failed to recv resp: ".. err)
			break
		end
		buf = buf..rt.."\r\n"
		i = i + 1
	end
	return buf
end


function send_redis_socket_data(redis_socket,data)
	local rt, err = redis_socket:send(data)
	if not rt then
		ngx_util.error_log("redis.lua		failed to send data ", err)
		return false
	end
	return true
end


function set_redis_socket_keepalive(redis_socket)
	rt, err = redis_socket:setkeepalive(0, 300)
	if not rt then
		ngx_util.debug_log("redis.lua		failed to set keepalive: ".. err)
	end
end


local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
