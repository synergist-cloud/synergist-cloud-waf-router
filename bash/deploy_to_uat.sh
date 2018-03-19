#!/bin/bash

#rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@dev.synergist.cloud:/etc/nginx/conf/nginx.conf
#rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/control_panel_handler.lua root@dev.synergist.cloud:/etc/nginx/lua/scripts/control_panel_handler.lua

#ssh root@dev.synergist.cloud 'nginx -s reload'


rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@local3.alsop:/usr/local/openresty/nginx/conf/nginx.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/control_panel_handler.lua root@local3.alsop:/usr/local/openresty/lua/scripts/control_panel_handler.lua

#ssh root@local3.alsop 'nginx -s reload'
ssh root@local3.alsop '/etc/init.d/nginx restart'
