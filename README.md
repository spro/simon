# simon
Nginx Lua + Redis module for consistent routing to backend servers by session ID. Inspired by hipache.

## Adding a backend

```
redis sadd backends:[host] [ip]:[port]
```

## In `nginx.conf`

Make sure to compile with Lua support and include [lua-resty-redis](https://github.com/openresty/lua-resty-redis)

```
http {

    ...
    
    lua_package_path "/opt/nginx/lib/resty/redis.lua;;"

    server {
    
        location / {
            set $proxy_to "";
            access_by_lua_file "/opt/nginx/lib/simon.lua";
            proxy_pass http://$proxy_to;
        }
        
        ...
        
    }
    
}
```
