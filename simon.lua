local cjson = require 'cjson'
local cookie = require 'cookie'
local redis = require 'redis'

local ck = cookie:new()
local red = redis:new()
red:connect('127.0.0.1', 6379)

local sid, err = ck:get('connect.sid')
if sid then
    local shost, err = red:get('sid:' .. sid)
    if shost ~= ngx.null then
        ngx.var.proxy_to = shost
        return
    end
end

-- Get new one
local headers = ngx.req.get_headers()
local hosts = red:smembers('frontend:' .. headers['host'])
local chosen = hosts[math.random(#hosts)]
ngx.var.proxy_to = chosen
if sid then red:set('sid:' .. sid, chosen) end

