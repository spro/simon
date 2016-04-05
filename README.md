# simon
dynamic routing/vhosts with nginx + Lua + Redis. Largely inspired by [hipache](https://github.com/hipache/hipache), a standalone proxy that does the same thing.

# Usage

When a request hits Simon, Simon looks in Redis for a set called `backends:[hostname]` and passes the location it finds to `proxy_pass`, and nginx proxies your request there. To add a route, add it to the proper Redis set:

```
sadd backends:[hostname] [ip]:[port]
```

## Examples

Use with a local nginx server and dnsmasq to make easy aliases for local projects:

```
> redis-cli sadd backends:project.dev 127.0.0.1:5520
1

> curl project.dev
<h1>Welcome to project.dev</h1>
```

Or on a server to distribute requests for a certain subdomain:

```
> redis-cli sadd backends:api.tryna.io 107.53.26.48:2280 107.52.2.16:2280 57.63.86.48:2280
3

> curl api.tryna.io
<a href='http://areyoutryna.com/'>are you tryna?</a>
```

If you add multiple backends to a set, new visitors will be randomly directed to one of the members as a rough form of load balancing. If a session ID is present (currently using the Express/Connect default `cookie_connect.sid`) it will be used to keep returning visitors consistently hitting one backend.

# Installation

Make sure to [compile nginx with Lua support](https://github.com/openresty/lua-nginx-module#installation) and include [lua-resty-redis](https://github.com/openresty/lua-resty-redis) and [lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie)

## Add to `nginx.conf`:

```
http {

    ...
    
    lua_package_path "/opt/nginx/lua/resty/?.lua";

    server {
    
        location / {
            set $proxy_to "";
            access_by_lua_file "/opt/nginx/lua/simon/simon.lua";
            proxy_pass http://$proxy_to;
            proxy_set_header Host $http_host;
        }
        
        ...
        
    }
    
}
```

## TODO

* Custom error pages (shows generic Nginx error if no hostname matches)
* Configurable cookie name (currently hard coded as Express/Connect's default `cookie_connect.sid`)
