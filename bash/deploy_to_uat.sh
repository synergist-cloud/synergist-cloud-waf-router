#!/bin/bash

rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@dev.synergist.cloud:/etc/nginx/conf/nginx.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/control_panel_handler.lua root@dev.synergist.cloud:/etc/nginx/lua/scripts/control_panel_handler.lua

ssh root@dev.synergist.cloud 'nginx -s reload'
