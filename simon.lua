-- Connect to Redis
local redis = require 'redis'
local red = redis:new()
red:connect('127.0.0.1', 6379)

-- Get session ID from cookie
local sid = ngx.var['cookie_connect.sid']

if sid then

    -- Check for an assigned backend
    local backend, err = red:get('sid:' .. sid)

    -- Use the assigned backend if it exists
    if backend ~= ngx.null then
        ngx.var.proxy_to = backend
        return
    end

end

-- Choose a random backend based on the host
local headers = ngx.req.get_headers()
local backends = red:smembers('backends:' .. headers['host'])
local chosen = backends[math.random(#backends)]

if sid then red:set('sid:' .. sid, chosen) end

-- Set chosen proxy server
ngx.var.proxy_to = chosen

