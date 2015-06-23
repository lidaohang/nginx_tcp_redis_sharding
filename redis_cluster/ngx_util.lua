local require = require
local setmetatable = setmetatable

local ngx=ngx

module(...)

_VERSION = '0.1'


--Ngx.DEBUG
function debug_log(mess)
	ngx.log(ngx.DEBUG,mess)
end

--Ngx.ERR
function error_log(mess)
	ngx.log(ngx.ERR,mess)
end


--获取请求的URL
function get_request_url()
	return ngx.req.get_headers()["Host"]..getRequestUri()
end

--获取请求的Host
function get_request_host()
	return ngx.req.get_headers()["Host"]
end

--获取请求的Uri
function get_request_uri()
	return ngx.var.uri
end

--正则匹配uri
function match_regex_string(info,regex)
	local m = ngx.re.match(info,regex)
	--用ngx.re.match就不能%d,用string.match就不能{2}
	--local m=ngx.re.match(info,regex) --linux
	--m=string.match(ngx.var.uri,regex[1])  --win
	return m
end

--设置Ngx的Uri
function set_ngx_uri(arge,enabled)
	ngx.req.set_uri(arge,enabled)
end

--获取cookies
function get_ngx_cookies()
	return ngx.var.http_cookie
end

--设置cookies
function set_ngx_cookies(pData)
	ngx.header['Set-Cookie'] =  pData
end

--获取客户端IP
function get_client_ip()
	local client_ip = ngx.req.get_headers()["X-Real-IP"]
	if client_ip == nil then
		client_ip = ngx.req.get_headers()["x_forwarded_for"]
	end
	if client_ip == nil then
		client_ip = ngx.var.remote_addr
	end
	return client_ip
end

--Ngx.Null
function get_ngx_null()
	return ngx.null
end

--Md5
function get_md5(str)
	return ngx.md5(str)
end

function get_request_body_param(key)
	ngx.req.read_body()
	local args = ngx.req.get_post_args()
	local data
	if args ~= nil then
		data=args[key]
	end
	return data
end

function get_current_url(suffix)
    if suffix == nil or suffix == "" then
	    return get_request_url()
	end
	
	local position = string.find(suffix,"http")
	
	if position ~= nil then 
	    return suffix
	else
       return get_request_url()..suffix	 	
	end
end

--拆分字符串
function split_string(info, split)  
	local rt= {}
	if not info then
		return nil
	end
	
	if info=="" then
		return nil
	end
	
    string.gsub(info, '[^'..split..']+', function(w) table.insert(rt, w) end )
    return rt 
end

--设置ngx环境变量
function set_variable_url(url)
	ngx.var.res=url
end



local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
