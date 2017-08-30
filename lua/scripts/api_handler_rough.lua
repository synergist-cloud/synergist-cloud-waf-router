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

        resolver                  8.8.8.8 valid=300s;


    location /api_request {
       content_by_lua_block {
           local inputContentStr= {}
           local outputData = {}
           local cjson = require 'cjson'

           if ngx.req.get_method() == "POST" then
	      ngx.req.get_body_data()
	      local success, response = pcall(cjson.decode, ngx.var.request_body)
              if success then
	      	 ngx.say(""..cjson.encode(response))
	      end
	   elseif ngx.req.get_method() == "GET" then
	     local args = ngx.req.get_uri_args()
	     for key, val in pairs(args) do
                            if type(val) == "table" then
                             --ngx.say(key, ": ", table.concat(val, ", "))
                            else
                                inputContentStr[key] = val
                            end
                       end
		       ngx.say(""..cjson.encode(inputContentStr))
	   else
		ngx.say("invalid method: " .. ngx.req.get_body_data())
    	   end
       }
    }
	location /api_set_key {
            content_by_lua_block {
	    	local inputContentStr= {}
		local outputData = {}
		local cjson = require 'cjson'

		local unique_str = ngx.var.arg_unique_value or ""
		local unique_prefix = ngx.var.arg_unique_prefix or ""
		if( unique_str ~= "" and unique_prefix ~= "" )
                then
			local args = ngx.req.get_uri_args()
			unique_str = unique_prefix..":"..unique_str

			for key, val in pairs(args) do
		    	    if type(val) == "table" then
                   	     --ngx.say(key, ": ", table.concat(val, ", "))
			    else
				inputContentStr[key] = val
		    	    end
         	       end
		      --ngx.say(""..cjson.encode(inputContentStr))
		      local timeLocalNow = os.time(os.date('*t'))

			inputContentStr["modified"] = timeLocalNow

		       local redis = require "resty.redis"
                       local red = redis:new()

                       red:set_timeout(1000) -- 1 sec
		       
                       local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                       if not ok then
                       	    outputData['error'] = "Failed to connect: "..err
			    ngx.say(cjson.encode(outputData))
			end

			ok, err = red:set(unique_str, cjson.encode(inputContentStr))
                        if not ok then
                              outputData['error'] = "Failed to set "..unique_str..": "..err
                              ngx.say(cjson.encode(outputData))
                              return
                        end

			-- or just close the connection right away:
                 	local ok, err = red:close()
                 	if not ok then
                    	   outputData['error'] = "Failed to close".. err
                    	      ngx.say(cjson.encode(outputData))
                    	      return
                 	end	
			
			outputData["success"] = "OK"
                        ngx.say(cjson.encode(outputData))
			return	
		else
			outputData['error'] = "Please pass the required parameters"
                	ngx.say(cjson.encode(outputData))
		end
               }
        }
	location /api_get_key {
            content_by_lua_block {
                local unique_str = ngx.var.arg_key or ""
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

                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            outputData['error'] = "Failed to close".. err
                            ngx.say(cjson.encode(outputData))
                            return
                         end
			 ngx.say(cjson.encode(outputData))
                         return
                 else
                        outputData['error'] = "Please pass the required parameters"
                        ngx.say(cjson.encode(outputData))
                 end
            }
        }
	location /api_delete_key {
	    content_by_lua_block {
                local unique_str = ngx.var.arg_key or ""
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

                         local res, err = red:del(unique_str)
                         if not res then
                            outputData['error'] = "Failed to delete "..unique_str..": "..err
                            ngx.say(cjson.encode(outputData))
                            return
                         end

                         outputData['success'] = unique_str.." deleted successfully!"

                         -- or just close the connection right away:
                         local ok, err = red:close()
                         if not ok then
                            outputData['error'] = "Failed to close".. err
                            ngx.say(cjson.encode(outputData))
                            return
                         end
			 ngx.say(cjson.encode(outputData))
                         return
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
			     prefix_str = prefix_str..'*'
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

	location /api_update_oauth_value {
        	 content_by_lua_block {
        	      local cjson = require 'cjson'
               	      local auth_token_str = ngx.var.arg_auth or ""
               	      local token_str =ngx.var.arg_key or ""

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
		    local timeLocalNow = os.time(os.date('*t'))
		    tempValue["modified"] = timeLocalNow
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
		   --ngx.say(""..cjson.encode(inputContentStr))
		   local timeLocalNow = os.time(os.date('*t'))
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
		
		   unique_str = "site:"..unique_str
		   local get_res, get_err = red:get(unique_str)
		   if not get_res then
		      inputContentStr["created"] = timeLocalNow
		   end

		   if get_res == ngx.null then
		      inputContentStr["created"] = timeLocalNow
		   else
		       local tempExistingValueArr = cjson.decode(get_res)
		       if(tempExistingValueArr["hosts"] and (tempExistingValueArr["hosts"]~="")) then
		          local existingHostsArr= cjson.decode(tempExistingValueArr["hosts"])
			  local i=1
			  while ( i <= table.getn(existingHostsArr) ) do
			      red:del("host:"..existingHostsArr[i]["host_name"])
			      i = i+1
			  end
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
			      for key, val in pairs(inputContentStr) do
			      	  if(key~="hosts") then
				     tempHostContentArr[key] = val
				  end 
			      end 
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
		   return
		 else
		    outputData['error'] = "Please pass the required parameters"
                    ngx.say(cjson.encode(outputData))
		 end
               }
        }
}