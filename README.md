# simon
Nginx Lua + Redis module for dynamic routing to backend servers by hostname. Inspired by [hipache](https://github.com/hipache/hipache).

## Adding a backend

```
redis sadd backends:[host] [ip]:[port]
```

**Note:** If you add multiple backends to a set, visitors will be randomly directed to one of the members as a rough form of load balancing. If a session ID is present (currently using the Express default `cookie_connect.sid`) it will be used to keep visitors consistently hitting one backend.

## In `nginx.conf`

Make sure to [compile nginx with Lua support](https://github.com/openresty/lua-nginx-module#installation) and include [lua-resty-redis](https://github.com/openresty/lua-resty-redis) and [lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie)

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
