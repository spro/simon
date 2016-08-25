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

If you add multiple backends to a set, new visitors will be randomly directed to one of the members as a rough form of load balancing. If a session ID is present (read from the cookie "cookie_connect.sid" by default) it will be used to consistently direct visitors to one backend.

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
