# simon
Nginx Lua + Redis module for consistent routing to backend servers by session ID. Inspired by hipache.

## Adding a backend

```
redis sadd backends:[host] [ip]:[port]
```

## In `nginx.conf`

Make sure to [compile nginx with Lua support](https://github.com/openresty/lua-nginx-module#installation) and include [lua-resty-redis](https://github.com/openresty/lua-resty-redis)

```
http {

    ...
    
    lua_package_path "/opt/nginx/lua/resty/redis.lua;;"

    server {
    
        location / {
            set $proxy_to "";
            access_by_lua_file "/opt/nginx/lua/simon.lua";
            proxy_pass http://$proxy_to;
            proxy_set_header Host $http_host;
        }
        
        ...
        
    }
    
}
```
