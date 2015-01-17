local cookie = require 'cookie'
local redis = require 'redis'

local ck = cookie:new()
local red = redis:new()
red:connect('127.0.0.1', 6379)

local sid, err = ck:get('connect.sid')
if sid then
    local backend, err = red:get('sid:' .. sid)
    if backend ~= ngx.null then
        ngx.var.proxy_to = backend
        return
    end
end

-- Get new one
local headers = ngx.req.get_headers()
local backends = red:smembers('backends:' .. headers['host'])
local chosen = backends[math.random(#backends)]
ngx.var.proxy_to = chosen
if sid then red:set('sid:' .. sid, chosen) end

