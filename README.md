# simon
Dynamic routing / virtual hosts with nginx, Lua, and Redis.

Simon allows you to very quickly point domains to specific ports by setting up dynamic `proxy_pass` directives. Largely inspired by [hipache](https://github.com/hipache/hipache), a standalone proxy that does the same thing.

![simon](https://github.com/spro/simon/blob/master/simon.png?raw=true)

# Usage

When a request hits Simon, Simon looks in Redis for a set called `backends:[hostname]` and passes the location it finds to `proxy_pass`, and nginx proxies your request there. To add a route, add it to the proper Redis set:

```
> redis-cli sadd backends:[hostname] [ip]:[port]
```

## Basic example

Point `example.dev` to local port 8080

```
> redis-cli sadd backends:example.dev 127.0.0.1:8080
1

> curl example.dev
<h1>Welcome to example.dev</h1>
```

## Load balancing

Distribute requests for `api.example.dev` to ports 5566 and 5577:

```
> redis-cli sadd backends:api.example.dev 127.0.0.1:5566 127.0.0.1:5577
2

> curl api.example.dev
{"success": "definitely"}
```

If you add multiple backends to a set, new visitors will be randomly directed to one of them as a rough form of load balancing. If a session ID is present (using the cookie "cookie_connect.sid" by default) simon will direct subsequent visits to the same backend.

## Wildcard domains

You can use an asterisk "\*" to define a catch-all for a single level; "*.example.dev" will match "hello.example.dev" but not "api.staging.example.dev":

```
> redis-cli sadd backends:*.example.dev 127.0.0.1:8080
1

> curl ww3.example.dev
<h1>Welcome to example.dev</h1>
```

# Installation

* Compile nginx with Lua support (e.g. with [OpenResty](http://openresty.org/en/download.html))

```
apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
tar -xzvf openresty-VERSION.tar.gz
cd openresty-VERSION/
./configure  --with-luajit --prefix=/opt/openresty
make && sudo make install
```

* Clone simon into `/opt/openresty/lualib/`

```
cd /opt/openresty/lualib/
git clone http://github.com/spro/simon
```

* Add to `/opt/openresty/nginx/conf/nginx.conf`

```
http {

    ...
    
    lua_package_path "/opt/openresty/lualib/resty/?.lua";

    server {
    
        location / {
            set $proxy_to "";
            access_by_lua_file "/opt/openresty/lualib/simon/simon.lua";
            proxy_pass http://$proxy_to;
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-For $remote_addr;
        }
        
        ...
        
    }
    
}
```

# Options

* `cookie_key` (default "cookie_connect.sid"): Name of the cookie from which a session ID should be read.

Usage: above `access_by_lua_file`, add the line `set $cookie_key "custom_cookie_key"`

## TODO

* Custom error pages (shows generic Nginx error if no hostname matches)
