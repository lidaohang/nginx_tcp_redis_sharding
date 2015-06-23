ngx.log(ngx.DEBUG,"request to begin------------------------------------------------ \r\n")
local redissocket=require "redissocket"

local req=redissocket.getReqSocket()	 --获取当前请求

--接收当前请求的数据包INFO命令
ngx.log(ngx.DEBUG,"start to req:receive ")
local buf = redissocket.getReqSocketReceive(req)
if buf == nil then
	return
end
ngx.log(ngx.DEBUG,"succeed to req:receive buf "..buf)	--print 请求的数据包

--如果是INFO就直接发送数据包
if buf == "*1\r\n$4\r\nINFO\r\n" then
	buf="$1003\r\nredis_version:2.4.16\r\nredis_git_sha1:00000000\r\nredis_git_dirty:0\r\narch_bits:64\r\nmultiplexing_api:epoll\r\ngcc_version:4.4.6\r\nprocess_id:29240\r\nuptime_in_seconds:541225\r\nuptime_in_days:6\r\nlru_clock:1067\r\nused_cpu_sys:221.25\r\nused_cpu_user:131.05\r\nused_cpu_sys_children:0.00\r\nused_cpu_user_children:0.00\r\nconnected_clients:2\r\nconnected_slaves:0\r\nclient_longest_output_list:0\r\nclient_biggest_input_buf:0\r\nblocked_clients:0\r\nused_memory:742128\r\nused_memory_human:724.73K\r\nused_memory_rss:22011904\r\nused_memory_peak:14598136\r\nused_memory_peak_human:13.92M\r\nmem_fragmentation_ratio:29.66\r\nmem_allocator:jemalloc-3.0.0\r\nloading:0\r\naof_enabled:0\r\nchanges_since_last_save:149901\r\nbgsave_in_progress:0\r\nlast_save_time:1362618254\r\nbgrewriteaof_in_progress:0\r\ntotal_connections_received:2767\r\ntotal_commands_processed:4537064\r\nexpired_keys:73876\r\nevicted_keys:0\r\nkeyspace_hits:4234557\r\nkeyspace_misses:150727\r\npubsub_channels:0\r\npubsub_patterns:0\r\nlatest_fork_usec:0\r\nvm_enabled:0\r\nrole:master\r\ndb0:keys=4,expires=0\r\n\r\n"
	ngx.log(ngx.DEBUG,"send INFO to buf end")
	ngx.print(buf)
	
	--接收当前请求的数据包操作command命令
	ngx.log(ngx.DEBUG,"start to req:receive ")
	buf = redissocket.getReqSocketReceive(req)
	if buf == nil then
		return
	end
end	

local serversocket=nil

--发送buf到Redissocket
ngx.log(ngx.DEBUG,"succeed to upsock:send buf "..buf)
serversocket=redissocket.sendRedisSocketData(buf)
if serversocket == nil then
	return
end		
		
--接收RedisSocket返回的数据	
buf = redissocket.getRedisSocketReceive(serversocket)
if buf == nil then
	return
end		
			
ngx.log(ngx.DEBUG,"succeed to upsock:receive buf "..buf)
ngx.log(ngx.DEBUG,"succeed to upsock:receive end ")
ngx.print(buf)
	

--设置keepalive保持连接	
redissocket.setKeepaLive(serversocket)
ngx.log(ngx.DEBUG,"request to end------------------------------------------------ \r\n")
