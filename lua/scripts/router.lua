ngx.status = 200
ngx.header.content_type = 'text/html'

        --local h = ngx.req.get_headers()
        --for k, v in pairs(h) do
            --ngx.say(k, ": ", v)
        --end

local template = require "resty.template"
template.render("index-template.html", { messageStr = "matrix.sh!", systemInfoTxt =  ngx.req.raw_header() })

--ngx.exit(ngx.HTTP_OK)

--return

--ngx.say("Hello, world from router.lua!")

--ngx.header.content_type = 'text/html'
--ngx.say("Hello, world from route.lua!")