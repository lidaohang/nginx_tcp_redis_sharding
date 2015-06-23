redisserver=require "redisserver"
local redissocket={}

function createRedisSocket()
	local serversocket=ngx.socket.tcp()  --建立一个tcp
	return serversocket
end



--获取当前请求
function redissocket.getReqSocket()
	local req = ngx.req.socket()   
	req:settimeout(1000)
	return req
end


--获取当前请求socket接收的数据
function redissocket.getReqSocketReceive(req)
	local rt, err = req:receive()
	if not rt then
        ngx.log(ngx.ERR, "failed to recv req: ".. err)
        return nil
    end
	 
	local r = rt:byte(1,1)
	cnt = 0
	ngx.log(ngx.DEBUG,"redissocket.getReqSocketReceive  r "..r)
	if r == 42 then    -- 42(*) 返回多个块数据
		cnt = tonumber(rt:sub(2))
	else
		ngx.log(ngx.ERR, "read a non * line")	--数据格式错误
		cnt = 0
	end
	
	buf = rt.."\r\n"
	local i = 1
	ngx.log(ngx.DEBUG,"redissocket.getReqSocketReceive  rt "..rt)
	while i <= cnt * 2 do		--构建接收到数据格式
		rt, err = req:receive()
		if not rt then
			ngx.log(ngx.ERR, "failed to recv req: " .. err)
			return nil
		end
		buf = buf..rt.."\r\n"
		i = i + 1
	end
    return buf
end

function splitStr(szFullString, szSeparator)  
	local rt= {}
    string.gsub(szFullString, '[^'..szSeparator..']+', function(w) table.insert(rt, w) end )
    return rt 
end

function getSplitKey(info)
	local findStr=splitStr(info,"$")
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


--发送数据包
function redissocket.sendRedisSocketData(buf)
	local flexiHash=_G["flexiHashGbl"]
	
	local key=getSplitKey(buf)
	local ipserver = flexiHash:lookup(key)
	ngx.log(ngx.DEBUG,"redissocket.sendRedisSocketData key "..key)
	ngx.log(ngx.DEBUG,"redisAddr  "..ipserver)
	
	local ip=string.sub(ipserver,1,string.find(ipserver,":")-1)
	local port=string.sub(ipserver,string.find(ipserver,":")+1,string.len(ipserver))
	
	ngx.log(ngx.DEBUG,"redisAddr ip  "..ip)
	ngx.log(ngx.DEBUG,"redisAddr port  "..port)
	local serversocket=createRedisSocket()
	local rt, err = serversocket:connect(ip, tonumber(port))
	if not rt then
		ngx.log(ngx.ERR,"failed to connect: ", err)
		return nil
	end
	
	local rt, err = serversocket:send(buf)
	if not rt then
		ngx.say("failed to sendRedisSocketData send: ", err)
		return nil
	end
	return serversocket
end

--接收redisSocket数据包
function redissocket.getRedisSocketReceive(serversock)
	local rt, err = serversock:receive()
	if not rt then
		ngx.log(ngx.ERR, "failed to recv first resp: " .. err)
		return nil
	end
		
	local r = rt:byte(1,1)
	local cnt = 0
	local buf = rt.."\r\n"
	ngx.log(ngx.DEBUG,"succeed to upsock:receive buf "..buf)
	
	ngx.log(ngx.DEBUG,"succeed to upsock:receive r "..r)
	if r == 36 then  -- $返回响应的数据块
		ngx.log(ngx.DEBUG, "upsock:receive buf  " .. buf)
		rt, err = serversock:receive()
		if not rt then
			ngx.log(ngx.ERR, "failed to recv single resp: " .. err)
			return nil
		end
		buf = buf..rt.."\r\n"
	--elseif r == 45 or r == 43 or r == 58 then  -- 45(-)代表发送了错误   43(+)代表一个状态信息如 +ok  58(:)返回的是一个整数  格式如：":11\r\n
	--	ngx.log(ngx.DEBUG,"succeed to upsock:receive (45-,43+) r "..r)
	elseif  r == 42 then    -- *返回多个块数据
		cnt = tonumber(rt:sub(2))
	end
			
	local i = 1
	while i <= cnt * 2 do
		rt, err = serversock:receive()
		if not rt then
			ngx.log(ngx.ERR, "failed to recv resp: ".. err)
			break
		end
		buf = buf..rt.."\r\n"
		i = i + 1
	end
	return buf
end

--设置setkeepalive，保持连接
function redissocket.setKeepaLive(serversock)
	rt, err = serversock:setkeepalive(0, 300)
	if not rt then
		ngx.log(ngx.DEBUG, "failed to set keepalive: ".. err)
	end
end



return redissocket
