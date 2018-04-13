
#!/bin/bash

#rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@dev.synergist.cloud:/etc/nginx/conf/nginx.conf
#rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/control_panel_handler.lua root@dev.synergist.cloud:/etc/nginx/lua/scripts/control_panel_handler.lua

#ssh root@dev.synergist.cloud 'nginx -s reload'


rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@local3.alsop:/usr/local/openresty/nginx/conf/nginx.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/webcrm.io.conf root@local3.alsop:/usr/local/openresty/nginx/conf/webcrm.io.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/static_images.conf root@local3.alsop:/usr/local/openresty/nginx/conf/static_images.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/upstreams.conf root@local3.alsop:/usr/local/openresty/nginx/conf/upstreams.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/cache.conf root@local3.alsop:/usr/local/openresty/nginx/conf/cache.conf
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/control_panel_handler.lua root@local3.alsop:/usr/local/openresty/lua/scripts/control_panel_handler.lua
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/router.lua root@local3.alsop:/usr/local/openresty/lua/scripts/router.lua
rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/lua/scripts/on_waf_failed_event.lua root@local3.alsop:/usr/local/openresty/lua/scripts/on_waf_failed_event.lua

rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/html/ root@local3.alsop:/usr/local/openresty/nginx/html/
rsync -avzx --exclude=".*" /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/html/platform/ root@local3.alsop:/usr/local/openresty/nginx/html/platform/

rsync -avzx /Users/balinderwalia/Documents/WebApplications/synergist-cloud-waf-router/conf/nginx.conf root@local3.alsop:/usr/local/openresty/nginx/conf/nginx.conf

#ssh root@local3.alsop 'nginx -s reload'
#ssh root@local3.alsop '/etc/init.d/nginx restart'
ssh root@local3.alsop '/usr/local/openresty/nginx/sbin/nginx -s stop'
ssh root@local3.alsop '/usr/local/openresty/nginx/sbin/nginx'
