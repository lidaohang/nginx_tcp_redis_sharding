local ngx_util=require "ngx_util"
ngx_util.debug_log("request to begin------------------------------------------------ \r\n")

local redis=require "redis"

local req_socket=redis.get_req_socket()	 --获取当前请求

--接收当前请求的数据包INFO命令
ngx_util.debug_log("start to req:receive ")
local data = redissocket.get_req_socket_receive(req_socket)
if data == nil then
	return
end
ngx_util.debug_log("succeed to req:receive buf "..data)	--print 请求的数据包

--如果是INFO就直接发送数据包
if data == "*1\r\n$4\r\nINFO\r\n" then
	data="$1003\r\nredis_version:2.4.16\r\nredis_git_sha1:00000000\r\nredis_git_dirty:0\r\narch_bits:64\r\nmultiplexing_api:epoll\r\ngcc_version:4.4.6\r\nprocess_id:29240\r\nuptime_in_seconds:541225\r\nuptime_in_days:6\r\nlru_clock:1067\r\nused_cpu_sys:221.25\r\nused_cpu_user:131.05\r\nused_cpu_sys_children:0.00\r\nused_cpu_user_children:0.00\r\nconnected_clients:2\r\nconnected_slaves:0\r\nclient_longest_output_list:0\r\nclient_biggest_input_buf:0\r\nblocked_clients:0\r\nused_memory:742128\r\nused_memory_human:724.73K\r\nused_memory_rss:22011904\r\nused_memory_peak:14598136\r\nused_memory_peak_human:13.92M\r\nmem_fragmentation_ratio:29.66\r\nmem_allocator:jemalloc-3.0.0\r\nloading:0\r\naof_enabled:0\r\nchanges_since_last_save:149901\r\nbgsave_in_progress:0\r\nlast_save_time:1362618254\r\nbgrewriteaof_in_progress:0\r\ntotal_connections_received:2767\r\ntotal_commands_processed:4537064\r\nexpired_keys:73876\r\nevicted_keys:0\r\nkeyspace_hits:4234557\r\nkeyspace_misses:150727\r\npubsub_channels:0\r\npubsub_patterns:0\r\nlatest_fork_usec:0\r\nvm_enabled:0\r\nrole:master\r\ndb0:keys=4,expires=0\r\n\r\n"
	ngx_util.debug_log("send INFO to buf end")
	ngx.print(data) --send request client
	
	--接收当前请求的数据包操作command命令
	ngx_util.debug_log("start to req:receive ")
	data = redissocket.get_req_socket_receive(req_socket)
	if not buf then
		return
	end
end	


--get redis socket
local redis_socket=redis.get_redis_socket()
if not redis_socket then
	return
end

--send_redis_socket_data
ngx_util.debug_log("succeed to upsock:send buf "..data)
local status=redis.send_redis_socket_data(redis_socket,buf)
if status == false then
	return
end		
		
--get_redis_socket_receive
buf = redis.get_redis_socket_receive(redis_socket)
if not buf  then
	return
end		
			
ngx_util.debug_log("succeed to upsock:receive buf "..buf)
ngx_util.debug_log("succeed to upsock:receive end ")
ngx.print(buf) --send request client	

--set_redis_socket_keepalive
redis.set_redis_socket_keepalive(redis_socket)
ngx_util.debug_log("request to end------------------------------------------------ \r\n")
