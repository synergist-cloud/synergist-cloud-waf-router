ngx.status = 403
ngx.header.content_type = 'text/html'
ngx.say("WAF FAILED!")

--ngx.header.content_type = 'text/html'
--ngx.say("Hello, world from route.lua!")
