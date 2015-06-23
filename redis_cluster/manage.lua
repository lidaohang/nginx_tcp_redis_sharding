local require,pairs = require,pairs
local setmetatable = setmetatable

local ngx_util=require "ngx_util"
local Flexihash=require "Flexihash"

redisserver={
	new={ip="10.168.100.15",port=6330},
	auto={ip="10.168.100.187",port=6330}
}
local redisserver=redisserver
 
module(...)

_VERSION = '0.1'

function consistent_hash(key)
	ngx_util.debug_log("manage.lua		flexiHash init")
	local flexihash = Flexihash.New()

	if not redisserver then
		ngx_util.error_log("manage.lua		redisserver init")
	end


	for k,v in pairs(redisserver) do
		if v ~= nil then
			flexiHash:addTarget(v["ip"]..':'..v["port"])
		end
	end
	ngx_util.debug_log("manage.lua		flexiHash add OK")
	
	local ipserver = flexiHash:lookup(key)
	return ipserver
end




local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
