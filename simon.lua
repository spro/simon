-- Connect to Redis
local redis = require 'redis'
local red = redis:new()
red:connect('127.0.0.1', 6379)

-- Get session ID from cookie and host from headers
local sid = ngx.var[ngx.var.cookie_key or 'cookie_connect.sid']
local headers = ngx.req.get_headers()
local host = headers['host']
host = string.lower(string.gsub(host, "^www.", ""))

if sid then

    -- Check for an assigned backend
    local backend, err = red:get('sess:' .. host .. ':' .. sid)

    -- Use the assigned backend if it exists
    if backend ~= ngx.null then
        ngx.var.proxy_to = backend
        return
    end

end

-- Choose a random backend based on the host
local backends = red:smembers('backends:' .. host)

-- Try to find a wildcard definition if there's no match
if #backends == 0 then
    local host_parts = {}
    for token in string.gmatch(host, '([^.]+)') do
        table.insert(host_parts, token)
    end
    if #host_parts > 2 then
        table.remove(host_parts, 1)
        local host_trimmed = table.concat(host_parts, '.')
        backends = red:smembers('backends:*.' .. host_trimmed)
    end
end

local chosen = backends[math.random(#backends)]

if sid then red:set('sess:' .. host .. ':' .. sid, chosen) end

-- Set chosen proxy server
ngx.var.proxy_to = chosen
local proxy_host = red:get('backends:' .. host .. ':host')
if proxy_host ~= ngx.null then
    ngx.var.proxy_host = proxy_host
else
    ngx.var.proxy_host = ngx.var.http_host
end

