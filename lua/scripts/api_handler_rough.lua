init_by_lua '
   cjson = require("cjson") -- cjson is a global variable
   local redis = require "resty.redis"

   -- make connection to redis database 
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

   --close the database connection
   function close_db(dbhandle)
      local ok, err = dbhandle:close()
      if not ok then
         ngx.say("failed to disconnect", err)
         return
      end
   end
   
   --fetch the value of key
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

   --delete the key passed
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

   --set the key, key and value passed
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
  
   --process the template content which contain tokens
   function processTokens (db, templateContentStr)
      local searchParaCount=4
      local tempContentStr=templateContentStr;
      local findTokenStartingPos = string.find(tempContentStr, "</*--") 
  
      if (tempContentStr ~="" and findTokenStartingPos ~=nil and findTokenStartingPos>=0) then
         local findTokenEndingPos = string.find(tempContentStr, "--*>") 
         local tokenStr = string.sub(tempContentStr, findTokenStartingPos+searchParaCount, findTokenEndingPos-1)
         if(tokenStr ~= "") then
	   local replacementStr = ""
	   local res = get_key(db, "token:"..tokenStr)
	   if( res and res["aaData"] and res["aaData"] ~= "") then	
	       local token_data_arr = cjson.decode(res["aaData"])
	       local tokenContentStr = token_data_arr["content"]

	       local temptokenStr= string.gsub(tokenStr, "%-", "%%-")

	       local findTokenInTempStr= string.find(tokenContentStr, temptokenStr)

	       if ( findTokenInTempStr ~=nil and findTokenInTempStr>=0) then
	       	  replacementStr = "* RECURSION : "..tokenStr.." *" 
	       else
	          replacementStr = tokenContentStr 
	       end
	   else
	       replacementStr = "Token "..tokenStr.." not found"
	   end

           local tempContentStr = string.gsub(templateContentStr, "<%*.-%*>", replacementStr, 1)
           tempContentStr = processTokens(db, tempContentStr)
           return tempContentStr
         end
     else
        return tempContentStr
     end
  end
';
server {
    listen	*:80 default_server;
    default_type 'text/html';

    location / {
        resolver                  8.8.8.8 valid=300s;
	set $target '';
	access_by_lua '
	   local host_name_str = ngx.var.host

	   local db = connect_db()
           if db == nil then
	      return ngx.exit(500)
	   end
	   local res = get_key(db, "host:"..host_name_str)

	   if( res and res["aaData"] and res["aaData"] ~= "") then
	       local host_data_arr = cjson.decode(res["aaData"])

	       local rule_to_process = ""
	       if( host_data_arr and host_data_arr["rules"] and host_data_arr["rules"] ~="" ) then
	       	   local rulesArr = cjson.decode(host_data_arr["rules"])
		   local i = 1

		   --work in progress for this loop
		   while ( i <= table.getn(rulesArr) ) do
		   	 if ((rulesArr[i].active == 1 or rulesArr[i].active == "1") and (rulesArr[i].sort_order == 1 or rulesArr[i].sort_order == "1")) then
			       rule_to_process = rulesArr[i].rule
			       break
			 end 

			 i = i + 1
		   end
	       end

	       if ( rule_to_process ~= "" )  then
	       	  local rule_res = get_key(db, rule_to_process) 
		  if( rule_res and rule_res["aaData"] and rule_res["aaData"] ~= "") then
		      local rule_data_arr = cjson.decode(rule_res["aaData"])
		      if( rule_data_arr and rule_data_arr["rule_type"] and rule_data_arr["rule_type"] =="proxy_pass" and rule_data_arr["proxy_pass"] and rule_data_arr["proxy_pass"] ~="" ) then
		      	  ngx.var.target = rule_data_arr["proxy_pass"]  
		      end
		  end
	       else
	          return ngx.redirect("http://webcrm.io/")
	       end
	   else
		return ngx.redirect("http://webcrm.io/")
	   end
	   close_db(db)
	';
    	proxy_pass $target;
    }
}

server {
    listen       *:8081;
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
    location /read_write_file {
        content_by_lua_block {
	   local function requiref(module)
              require(module)
           end
           res = pcall(requiref,"io")
	   if not(res) then
	       ngx.say("Sorry, io module not found")
	   else
	       local file_path_str = "/etc/nginx/conf.d/test.lua"
	       local file = io.open(file_path_str, "r")
	       if file==nil
               then
                   ngx.say(file_path_str .. " can\'t read or does not exists")
                   return
		else
		   ngx.say("file found")
		   -- sets the default input file
                    io.input(file)

                    -- read the lines in table lines
                    for line in io.lines() do
 		    	ngx.say(line)
                    end
		    
		   io.close(file)
		end
	   end
	}
    }

    location /fetch_template_data {
      	content_by_lua_block {
	   local key_str = ngx.var.arg_key or ""
	   if( key_str ~= "" )
           then
		local db = connect_db()
                if db == nil then
                   outputData['error'] = "Failed to connect to database"
                   ngx.say(cjson.encode(outputData))
                   return
                end
                local res = get_key(db, key_str)
		if( res and res['error'] and res['error'] ~= "") then
		   ngx.say(cjson.encode(res))
		elseif( res['aaData'] and res['aaData'] ~= "") then
		   local contentData = cjson.decode(res['aaData'])
		   local tempContentStr= processTokens(db, contentData['content'], tokensArr)
		   contentData["content"] = tempContentStr
		   ngx.say(cjson.encode(contentData))
		else
		  outputData['error'] = "Template not found"
                  ngx.say(cjson.encode(outputData))
		end
		close_db(db)
                return
	   else
		ngx.say("Please pass the required parameters")
	   end
	}
    }	
    location /api_set {
    	content_by_lua_block {
	   local outputData = {}
	   local key_str = ngx.var.arg_key or ""
	   local value_str = ngx.var.arg_value or ""
	   if( key_str ~= "" and value_str ~= "" )
           then
		local db = connect_db()
                if db == nil then
                   outputData['error'] = "Failed to connect to database"
                   ngx.say(cjson.encode(outputData))
                   return
                end
		local res = set_key(db, key_str, value_str)
		ngx.say(cjson.encode(res))

		close_db(db)
		return
	   else
		ngx.say("Please pass the required parameters")
	   end
	}   
    }
    location /api_post_key {
       content_by_lua_block {
           local outputData = {}
           local key_str = ""
	   local value_str = ""
	      ngx.req.read_body()
              local args, err = ngx.req.get_post_args()
              if not args then
	      	 outputData['error'] = "Failed to get post args: "..err
              	 ngx.say(cjson.encode(outputData))
             	 return
              end
	      for key, val in pairs(args) do
		if key == "key" then
		   key_str = val
		elseif key == "value" then
		       value_str = val
                end
              end

	   if( key_str ~= "" and value_str ~= "" )
	   then
	       local inputContentStr = cjson.decode(value_str)
	       local timeLocalNow = os.time(os.date('*t'))
	       inputContentStr["modified"] = timeLocalNow
	       
	       local db = connect_db()
               if db == nil then
                    outputData['error'] = "Failed to connect to database"
                    ngx.say(cjson.encode(outputData))
                    return
               end

			local res = set_key(db, key_str, cjson.encode(inputContentStr))
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
		local outputData = {}
		local key_str = ngx.var.arg_key or ""
		local value_str = ngx.var.arg_value or ""
		local args = ngx.req.get_uri_args()
		for key, val in pairs(args) do
		    if key == "key" then
		       key_str= val
		    elseif key == "value" then
		       value_str = val
		    end
		end

		if( key_str ~= "" and value_str ~= "" )
                then
		    local inputContentStr = cjson.decode(value_str)
		    local timeLocalNow = os.time(os.date('*t'))

			inputContentStr["modified"] = timeLocalNow
			
			local db = connect_db()
                        if db == nil then
                            outputData['error'] = "Failed to connect to database"
                            ngx.say(cjson.encode(outputData))
                            return
                        end
			
			local res = set_key(db, key_str, cjson.encode(inputContentStr))
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

			 local prefix_str = ngx.var.arg_search or ""
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
		local outputData = {}
		local key_str = ""
                local value_str = ""
                local args = ngx.req.get_uri_args()
                for key, val in pairs(args) do
                    if key == "code" then
                       key_str= val
                    elseif key == "value" then
                       value_str = val
                    end
                end

                if( key_str ~= "" and value_str ~= "" )
                then
			local inputContentStr = cjson.decode(value_str)

		   local timeLocalNow = os.time(os.date('*t'))
		   inputContentStr["modified"] = timeLocalNow

		   local db = connect_db()
                   if db == nil then
                      outputData['error'] = "Failed to connect to database"
                      ngx.say(cjson.encode(outputData))
                      return
		   end
		
		   key_str = "site:"..key_str

		   local get_res, get_err = db:get(key_str)
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

		   ok, err = db:set(key_str, cjson.encode(inputContentStr))
		   if not ok then
		      outputData['error'] = "Failed to set "..key_str..": "..err
		      ngx.say(cjson.encode(outputData))
		      return
		   end

		   if(inputContentStr["hosts"] and inputContentStr["hosts"]~="") then
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