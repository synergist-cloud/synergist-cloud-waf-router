server {
    listen       *:80 default_server;
    server_name  dev.synergist.cloud;

    return 301 https://dev.synergist.cloud/;
    break;

}

server {
    listen       *:443 default_server;
    server_name  dev.synergist.cloud;
    default_type 'text/html';

include includes/synergist_ssl_cert.conf;

        root   /usr/share/nginx/html;

    #charset koi8-r;                                                                                                                                                                                                                            
    #access_log  /var/log/nginx/log/host.access.log  main;                                                                                                                                                                                      

    error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html                                                                                                                                                                                  
    #                                                                                                                                                                                                                                           
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

location /hellolua {
    default_type 'text/html';

    content_by_lua '                                                                                                                                                                                                                            
        local name = ngx.var.arg_name or "Anonymous"                                                                                                                                                                                            
        ngx.say("Hello, ", name, "!")                                                                                                                                                                                                           
    ';
}



        resolver                  8.8.8.8 valid=300s;


        location /test {
            content_by_lua_block {

                local redis = require "resty.redis"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                -- or connect to a unix domain socket file listened
                -- by a redis server:
                --     local ok, err = red:connect("unix:/path/to/redis.sock")

                local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                ok, err = red:set("dog", "pet animal")
		    	  if not ok then
                    ngx.say("failed to set dog: ", err)
                    return
                end

                ngx.say("set result: ", ok)

                local res, err = red:get("dog")
                if not res then
                    ngx.say("failed to get dog: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("dog not found.")
                    return
                end

                ngx.say("dog: ", res)

                red:init_pipeline()
                red:set("cat", "Marry")
                red:set("horse", "Bob")
                red:get("cat")
                red:get("horse")
                local results, err = red:commit_pipeline()
                if not results then
                    ngx.say("failed to commit the pipelined requests: ", err)
                    return
                end

                for i, res in ipairs(results) do
                if type(res) == "table" then
                        if res[1] == false then
                            ngx.say("failed to run command ", i, ": ", res[2])
                        else
                            -- process the table value
                        end
                    else
                        -- process the scalar value
                    end
                end

                -- put it into the connection pool of size 100,
                -- with 10 seconds max idle time
                local ok, err = red:set_keepalive(10000, 100)
                if not ok then
                    ngx.say("failed to set keepalive: ", err)
                    return
                end

                -- or just close the connection right away:
                local ok, err = red:close()
                if not ok then
                     ngx.say("failed to close: ", err)
                     return
                 end
            }
        }


        location /gettest {
        	 content_by_lua_block {

                local redis = require "resty.redis"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                local res, err = red:get("dog")
                if not res then
                    ngx.say("failed to get dog: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("dog not found.")
                    return
                end

                ngx.say("dog: ", res)

                -- or just close the connection right away:
                 local ok, err = red:close()
                 if not ok then
                     ngx.say("failed to close: ", err)
                     return
                 end
            }
		}
	location /api_set_site {
            content_by_lua_block {
	    	local inputContentStr= {}
		local outputData = {}
		local cjson = require 'cjson'

		local unique_str = ngx.var.arg_code or ""

		if( unique_str ~= "" )
                then
			local args = ngx.req.get_uri_args()

			for key, val in pairs(args) do
		    	    if type(val) == "table" then
                   	     --ngx.say(key, ": ", table.concat(val, ", "))
			    else
				inputContentStr[key] = val
		    	    end
         	       end
		      -- ngx.say(""..cjson.encode(inputContentStr))
		      inputContentStr["modified"] = timeLocalNow

		       local redis = require "resty.redis"
                       local red = redis:new()

                       red:set_timeout(1000) -- 1 sec

                       local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                       if not ok then
                       	  outputData['error'] = "Failed to connect: "..err
                    	  ngx.say(cjson.encode(outputData))
                    	  return
               		end
			
			local timeLocalNow = os.time(os.date('*t'))
                	unique_str = "site:"..unique_str

                	local get_res, get_err = red:get(unique_str)
                	if get_res == ngx.null then
                   	   -- if not found add new
			   inputContentStr["created"] = timeLocalNow
                	end
			
			local tempExistingValueArr = cjson.decode(get_res)
			--remove existing hosts
			if(tempExistingValueArr["hosts"] and (tempExistingValueArr["hosts"]~="")) then
			   local existingHostsArr= cjson.decode(tempExistingValueArr["hosts"])
			   local i=1
			   while ( i <= table.getn(existingHostsArr) ) do
				 red:del("host:"..existingHostsArr[i]["host_name"])
				 i = i+1			
			   end
			end

			ok, err = red:set(unique_str, cjson.encode(inputContentStr))
                        if not ok then
                              outputData['error'] = "Failed to set "..unique_str..": "..err
                              ngx.say(cjson.encode(outputData))
                              return
                        end
			
			if(inputContentStr["hosts"]~="") then
			   local hostsContentArr = cjson.decode(inputContentStr["hosts"])
			   local l  = 1
      			   local m  = table.getn(hostsContentArr)
			   
			   while ( l <= m ) do
			       local tempHostName = "host:"..hostsContentArr[l].host_name
			       local tempHostContentArr = hostsContentArr[l]
			       --ngx.say("host"..cjson.encode(hostsContentArr[l]))
				for key, val in pairs(inputContentStr) do
                                   if(key~="hosts") then
				   tempHostContentArr[key] = val
				   end
				end
			       --ngx.say("host : "..cjson.encode(tempHostContentArr))
       			       red:set(tempHostName, cjson.encode(tempHostContentArr))
			       l = l + 1
      			   end
			end

			outputData["success"] = "OK"
		        ngx.say(cjson.encode(outputData))

			-- or just close the connection right away:
                 	local ok, err = red:close()
                 	if not ok then
                    	   outputData['error'] = "Failed to close".. err
                    	   ngx.say(cjson.encode(outputData))
                    	   return
                 	end			

		else
			outputData['error'] = "Please pass the required parameters"
                	ngx.say(cjson.encode(outputData))
		end
               }
        }

	location /api_set_url {
            content_by_lua_block {
                local token_str = ngx.var.arg_token or ""
                local service_str = ngx.var.arg_service or ""
                local link_str =ngx.var.arg_link or ""
		local cjson = require 'cjson'
		local outputData ={}
                if( link_str~="" and token_str~="" and service_str ~= "" )
                then
                local redis = require "resty.redis"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                if not ok then
                    outputData['error'] = "Failed to connect: "..err
		    ngx.say(cjson.encode(outputData))
		    return
                end

                local timeLocalNow = os.time(os.date('*t'))
		token_str = "url:"..token_str
		
		local get_res, get_err = red:get(token_str)
		if get_res == ngx.null then
		   -- if not found add new
		   local set_json_str='{"modified":'..timeLocalNow..',"created":'..timeLocalNow..', "link":"'..link_str..'", "service" : "'..service_str..'"}';

		   ok, err = red:setex(token_str, 86400, set_json_str)
                   if not ok then
                       outputData['error'] = "Failed to set "..token_str..": "..err
                       ngx.say(cjson.encode(outputData))
                       return
                   end

		else
			-- update content

			local tempValue=cjson.decode(get_res)
			tempValue['modified'] = timeLocalNow
			tempValue['link'] =	link_str
			tempValue['service'] = service_str
                    	tempValue = cjson.encode(tempValue)
			ok, err = red:set(token_str, tempValue)
                	if not ok then
                    	   outputData['error'] = "Failed to set "..token_str..": "..err
                    	   ngx.say(cjson.encode(outputData))
                    	   return
                	end
                end

                outputData["success"] = "OK"
		ngx.say(cjson.encode(outputData))

                -- or just close the connection right away:
                 local ok, err = red:close()
                 if not ok then
		    outputData['error'] = "Failed to close".. err
		    ngx.say(cjson.encode(outputData))
                    return
                 end

                 else
		 outputData['error'] = "Please pass the required parameters"
		 ngx.say(cjson.encode(outputData))
                 end
                 }
        }
	location /api_fetch_value {
	    content_by_lua_block {
                local unique_str = ngx.var.arg_unique or ""
                local cjson = require 'cjson'
                local outputData = {}
                if( unique_str~="" )
                    then
                        local redis = require "resty.redis"
                        local red = redis:new()

                        red:set_timeout(1000) -- 1 sec

                         local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                         if not ok then
                            outputData['error'] = "Failed to connect: "..err
                            ngx.say(cjson.encode(outputData))
                            return
                         end

                         local res, err = red:get(unique_str)
                         if not res then
                            outputData['error'] = "Failed to get "..unique_str..": "..err
                            ngx.say(cjson.encode(outputData))
                            return
                         end

                         if res == ngx.null then
                            outputData['error'] = unique_str.." not found."
                            ngx.say(cjson.encode(outputData))
                            return
                         end

                         outputData['success'] = "OK"
                         outputData['aaData']  = res
                         ngx.say(cjson.encode(outputData))

                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            outputData['error'] = "Failed to close".. err
                            ngx.say(cjson.encode(outputData))
                            return
                         end
                 else
                        outputData['error'] = "Please pass the required parameters"
                        ngx.say(cjson.encode(outputData))
                 end
            }
        }
        location /api_get_url_value {
            content_by_lua_block {
                local token_str = ngx.var.arg_token or ""
		local cjson = require 'cjson'
		local outputData = {}
		 if( token_str~="" )
                 then
                        local redis = require "resty.redis"
                        local red = redis:new()

                        red:set_timeout(1000) -- 1 sec

                         local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                         if not ok then
			    outputData['error'] = "Failed to connect: "..err
		            ngx.say(cjson.encode(outputData))
                            return
                         end
                       	 
			 token_str = "url:"..token_str
                         local res, err = red:get(token_str)
                         if not res then
                            outputData['error'] = "Failed to get "..token_str..": "..err
                            ngx.say(cjson.encode(outputData))
			    return
                         end

                         if res == ngx.null then
                            outputData['error'] = token_str.." not found."
			    ngx.say(cjson.encode(outputData))
                            return
                         end

			 outputData['success'] = "OK"
			 outputData['aaData']  = res
			 ngx.say(cjson.encode(outputData))

                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            outputData['error'] = "Failed to close".. err
			    ngx.say(cjson.encode(outputData))
                            return
                         end
                 else
			outputData['error'] = "Please pass the required parameters"
			ngx.say(cjson.encode(outputData))
                 end
            }
        }

        location /api_fetch_list {
                 content_by_lua_block {
                      local cjson = require 'cjson'
		     
		        local redis = require "resty.redis"
                        local red = redis:new()

                        red:set_timeout(1000) -- 1 sec

                         local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                         if not ok then
                            ngx.say("failed to connect: ", err)
                            return
                         end

			 local prefix_str = ngx.var.arg_prefix or ""
			 if( prefix_str~="" ) then
			     prefix_str = prefix_str..':*'
			 else
			     prefix_str = '*'
			 end
			 
			 local res, err = red:keys(prefix_str)
                         if not res then
			    ngx.say("failed to search: ", err)
                         end
			 local arrayVal = {}
			 local countNum = 0
			 for _,key in ipairs(res) do
                             countNum = countNum + 1
			     local val = red:get(key)

			     local tempObject ={}
			     tempObject["key"]=key
			     tempObject["value"]=val
			     arrayVal[countNum]= tempObject
                     	 end                      
			 local outputJson={}
			 outputJson["iTotalRecords"]=countNum
			 outputJson["aaData"]=arrayVal
			 ngx.say(cjson.encode(outputJson))
                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            ngx.say("failed to close: ", err)
                            return
                         end
                }
        }
        location /list_all_links {
                 content_by_lua_block {
                        local redis = require "resty.redis"
                        local red = redis:new()

                        red:set_timeout(1000) -- 1 sec

                         local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                         if not ok then
                            ngx.say("failed to connect: ", err)
                            return
                         end

                         local keys_str="<table width='100%' style='border-collapse: collapse;'><tr><th style='border: 1px solid #ddd;padding:10px;'>Key</th><th style='border: 1px solid #ddd;padding:10px;'>Value</th></tr>";

                         ngx.say(""..keys_str)
                         local res, err = red:keys('url:*')
                         if not res then
                            ngx.say("failed to close: ", err)
                         end

                         for _,key in ipairs(res) do
                             local val = red:get(key)
                      --      ngx.say("key: "..key)
                             ngx.say("<tr><td style='border: 1px solid #ddd;padding:10px;'>"..key.."</td><td style='border: 1px solid #ddd;padding:10px;'>"..val.."</td></tr>")
                         end
                         ngx.say("</table>")

                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            ngx.say("failed to close: ", err)
                            return
                         end
                }
        }
location /post_test {
     content_by_lua_block {
         local cjson = require 'cjson'
	 ngx.req.read_body()
         local args, err = ngx.req.get_post_args()
         if not args then
             ngx.say("failed to get post args: ", err)
             return
         end
local tempVal = cjson.encode(tostring(args))
	 ngx.say(tempVal["token"])
	 --[[
	 for key, val in pairs(args) do
             if type(val) == "table" then
              	ngx.say(key, ": ", table.concat(val, ", "))
             else
		--ngx.say(key,":: ", val)
		local tempVal = cjson.encode(tostring(key))
		ngx.say(tempVal["token"])	
             end
         end]]--
     }
 }
	location /api_update_oauth_value {
        	 content_by_lua_block {
        	      local cjson = require 'cjson'
               	      local auth_token_str = ngx.var.arg_auth or ""
               	      local token_str =ngx.var.arg_token or ""

               	      if( auth_token_str~="" and token_str~="")
               	      then
            	          local redis = require "resty.redis"
                	  local red = redis:new()

		          red:set_timeout(1000) -- 1 sec

    		          local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
        	          if not ok then
            	              ngx.say("failed to connect: ", err)
                              return
                	  end
  		
			token_str = "url:"..token_str
			local res, err = red:get(token_str)
                    if not res then
                       ngx.say("failed to get "..token_str..": ", err)
                        return
                    end

                    if res == ngx.null then
                       ngx.say(token_str.." not found.")
                        return
                    end
                    local tempValue=cjson.decode(res)
		    tempValue['oauth'] = auth_token_str
                    tempValue = cjson.encode(tempValue)

		    ok, err = red:set(token_str, tempValue)
                    if not ok then
                       ngx.say("failed to set "..token_str..": ", err)
                       return
               	    end

                    ngx.say(""..tempValue)

                    -- or just close the connection right away:
                    local ok, err = red:close()
                    if not ok then
                       ngx.say("failed to close: ", err)
                       return
                       end

                else
			ngx.say("Please pass the required parameters")
                end
            }
        }
        location /set_hm_link {
            content_by_lua_block {
                local token_str = ngx.var.arg_token or ""
                local service_str = ngx.var.arg_service or ""
                local link_str =ngx.var.arg_link or ""

                if( link_str~="" and token_str~="" and service_str ~= "" )
                then
                local redis = require "resty.redis"
                local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

                local timeLocalNow = os.time(os.date('*t'))
                local set_json_str="{'modified':"..timeLocalNow..", 'token_3rd_party':'"..token_str.."', 'service' : '"..service_str.."'}";

                ok, err = red:hmset(link_str, "modified", timeLocalNow, "token_3rd_party", token_str, "service", service_str)
                --ok, err = red:hmset("myhash", "field1", "Hello", "field2", "World")
                if not ok then
                    ngx.say("failed to set "..link_str..": ", err)
                         return
                end

                ngx.say("set result: ", ok)

                -- or just close the connection right away:
                 local ok, err = red:close()
                 if not ok then
                     ngx.say("failed to close: ", err)
                     return
                 end

                 else
                 ngx.say("Please pass the required parameters")
                 end
                 }
        }
}