redisserver={
	new={ip="10.168.100.15",port=6330},
	auto={ip="10.168.100.187",port=6330}
}

flexiHashGbl={}

local flexiHash=require("flexihash")
flexiHash = flexihash.New()
ngx.log(ngx.DEBUG,"flexiHash:addTarget init")

	
for k,v in pairs(redisserver) do
	if v ~= nil then
		flexiHash:addTarget(v["ip"]..':'..v["port"])
	end
end	
	
flexiHashGbl=flexiHash

return redisserver
