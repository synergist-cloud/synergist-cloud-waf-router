init_by_lua '
   cjson = require("cjson") -- cjson is a global variable
   local redis = require "resty.redis"
 
   function connect_db()
     local red = redis:new()
     red:set_timeout(1000) -- 1 sec
     local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
     if not ok then
        --ngx.say("failed to connect: ", err)
        return nil
     end
     return red
   end

   function close_db(dbhandle)
      local ok, err = dbhandle:close()
      if not ok then
         ngx.say("failed to disconnect", err)
         return
      end
   end
   
   function get_key(db, key)
      local outputData = {}
      local res, err = db:get(key)
      if not res then
          outputData["error"] = "Failed to get "..key..": "..err
	  return
      end

      if res == ngx.null then
          outputData["error"] = key.." not found."
	  return
      end
      outputData["success"] = "OK"
      outputData["aaData"]  = res
      return(outputData)
   end

   function del_key(db, key)
       local outputData = {}
       local res, err = db:del(key)
       if not res then
          outputData["error"] = "Failed to delete "..key..": "..err
          ngx.say(cjson.encode(outputData))
          return
       end
       outputData["success"] = key.." deleted successfully!"
       return(outputData)                                                                                                                                                                                            
   end 

   function set_key(db, key, value)
      local outputData = {}
      local ok, err = db:set(key, value)
      if not ok then
      	 outputData["error"] = "Failed to set "..key..": "..err
         ngx.say(cjson.encode(outputData))
         return
      end
      outputData["success"] = "OK"
      return(outputData) 
   end
';
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

    location /api_post_key {
       content_by_lua_block {
           local inputContentStr= {}
           local outputData = {}
           local unique_str = ""
           local unique_prefix = ""

	      ngx.req.read_body()
              local args, err = ngx.req.get_post_args()
              if not args then
	      	 outputData['error'] = "Failed to get post args: "..err
              	 ngx.say(cjson.encode(outputData))
             	 return
              end

           for key, val in pairs(args) do
             if type(val) == "table" then
             	inputContentStr[key] = table.concat(val, ", ")
             else
		if key == "unique_value" then
		   unique_str= val
		elseif key == "unique_prefix" then
		   unique_prefix = val
		else
		   inputContentStr[key] = val
		end
             end
           end

	   if( unique_str ~= "" and unique_prefix ~= "" )
	   then
	       local timeLocalNow = os.time(os.date('*t'))
	       inputContentStr["modified"] = timeLocalNow
	       
	       local db = connect_db()
               if db == nil then
                    outputData['error'] = "Failed to connect to database"
                    ngx.say(cjson.encode(outputData))
                    return
               end
		unique_str = unique_prefix..":"..unique_str
			local res = set_key(db, unique_str, cjson.encode(inputContentStr))
                        ngx.say(cjson.encode(res))

                        -- or just close the connection right away:
			close_db(db)
			return
           else
		outputData['error'] = "Please pass the required parameters"
                ngx.say(cjson.encode(outputData))
	   end
	   return
       }
    }
	location /api_set_key {
            content_by_lua_block {
	    	local inputContentStr= {}
		local outputData = {}

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
			
			local db = connect_db()
                        if db == nil then
                            outputData['error'] = "Failed to connect to database"
                            ngx.say(cjson.encode(outputData))
                            return
                        end
			
			local res = set_key(db, unique_str, cjson.encode(inputContentStr))
                        ngx.say(cjson.encode(res))

			-- or just close the connection right away:
			close_db(db)
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
		local outputData = {}
                if( unique_str~="" )
                    then
			local db = connect_db()
			if db == nil then
			    outputData['error'] = "Failed to connect to database"
                            ngx.say(cjson.encode(outputData))
                            return
         		end
			local res = get_key(db, unique_str)
			ngx.say(cjson.encode(res))
                        -- or just close the connection right away:
			close_db(db)
                        return
                 else
                        outputData['error'] = "Please pass the required parameters"
                        ngx.say(cjson.encode(outputData))
			return
                 end
            }
        }
	location /api_delete_key {
	    content_by_lua_block {
                local unique_str = ngx.var.arg_key or ""
                local outputData = {}
                if( unique_str~="" )
                    then
			local db = connect_db()
                        if db == nil then
                            outputData['error'] = "Failed to connect to database"
                            ngx.say(cjson.encode(outputData))
                            return
			end

			local res = del_key(db, unique_str)
			ngx.say(cjson.encode(res))

                         -- or just close the connection right away:
			 close_db(db)
                         return
                 else
                        outputData['error'] = "Please pass the required parameters"
                        ngx.say(cjson.encode(outputData))
                 end
            }
        }

        location /api_fetch_list {
                 content_by_lua_block {
		        local outputJson={}
		        local db = connect_db()
                        if db == nil then
                            outputJson['error'] = "Failed to connect to database"
                            ngx.say(cjson.encode(outputJson))
                            return
                         end

			 local prefix_str = ngx.var.arg_prefix or ""
			 if( prefix_str~="" ) then
			     prefix_str = prefix_str..'*'
			 else
			     prefix_str = '*'
			 end
			 
			 local res, err = db:keys(prefix_str)
                         if not res then
			    outputJson['error'] = "Failed to search"..err
                            ngx.say(cjson.encode(outputJson))
                            return
                         end
			 local arrayVal = {}
			 local countNum = 0
			 for _,key in ipairs(res) do
                             countNum = countNum + 1
			  
			     local res = get_key(db, key)
			     if( res['aaData'] and res['aaData'] ~= "") then
			        local tempObject ={}
			     	tempObject["key"]=key
			     	tempObject["value"]=cjson.encode(res['aaData'])
			     	arrayVal[countNum]= tempObject
			     end
                     	 end                      

			 outputJson["iTotalRecords"]=countNum
			 outputJson["aaData"]=arrayVal
			 ngx.say(cjson.encode(outputJson))

                         -- or just close the connection right away:
			 close_db(db)
                         return
                }
        }

	location /api_update_oauth_value {
        	 content_by_lua_block {
               	      local auth_token_str = ngx.var.arg_auth or ""
               	      local token_str =ngx.var.arg_key or ""

               	      if( auth_token_str~="" and token_str~="")
               	      then
		          local db = connect_db()
			  if db == nil then
                    	     ngx.say("failed to connect: ", err)
			     return
               		  end
  			  local res = get_key(db, token_str)
			  if( res and res['error'] and res['error'] ~= "") then
			      ngx.say(cjson.encode(res))
			  elseif( res and res['aaData'] and res['aaData'] ~= "") then
			      local tempValue = cjson.decode(res['aaData'])
			      tempValue['oauth'] = auth_token_str
			      local timeLocalNow = os.time(os.date('*t'))
                    	      tempValue["modified"] = timeLocalNow
			      tempValue = cjson.encode(tempValue)
			      
			      local res = set_key(db, token_str, tempValue)
			      ngx.say(cjson.encode(res))
			  else
				ngx.say(token_str.." not found.")
                          end

                    -- or just close the connection right away:
		    close_db(db);
		    return
                else
			ngx.say("Please pass the required parameters")
                end
            }
        }
	location /api_set_site {
            content_by_lua_block {
	    	local inputContentStr= {}
		local outputData = {}
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

		   local db = connect_db()
                   if db == nil then
                      outputData['error'] = "Failed to connect to database"
                      ngx.say(cjson.encode(outputData))
                      return
		   end
		
		   unique_str = "site:"..unique_str

		   local get_res, get_err = db:get(unique_str)
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
			      db:del("host:"..existingHostsArr[i]["host_name"])
			      i = i+1
			  end
		       end
		   end

		   ok, err = db:set(unique_str, cjson.encode(inputContentStr))
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
			      db:set(tempHostName, cjson.encode(tempHostContentArr))
			      l = l + 1
			end
		   end

		   outputData["success"] = "OK"
		   ngx.say(cjson.encode(outputData))

		   -- or just close the connection right away:
		   close_db(db);
		   return
		 else
		    outputData['error'] = "Please pass the required parameters"
                    ngx.say(cjson.encode(outputData))
		 end
               }
        }
}