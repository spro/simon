# simon
Dynamic routing / virtual hosts with nginx, Lua, and Redis.

Simon allows you to very quickly point domains to specific ports by setting up dynamic `proxy_pass` directives. Largely inspired by [hipache](https://github.com/hipache/hipache), a standalone proxy that does the same thing.

![simon](https://github.com/spro/simon/blob/master/simon.png?raw=true)

## Usage

For every request, Simon looks for a Redis Set called `backends:[hostname]` to find a destination for nginx's `proxy_pass`. To define a route, add a destination in the form `[ip]:[port]` to a Redis set `backends:[hostname]`:

```
> redis-cli sadd backends:[hostname] [ip]:[port]
```

### Basic example

Point `example.dev` to local port 8080:

```
> redis-cli sadd backends:example.dev 127.0.0.1:8080
1

> curl example.dev
<h1>Welcome to example.dev</h1>
```

### Load balancing

Distribute requests for `api.example.dev` to ports 5566 and 5577:

```
> redis-cli sadd backends:api.example.dev 127.0.0.1:5566 127.0.0.1:5577
2

> curl api.example.dev
{"success": "definitely"}
```

If Simon finds multiple destinations, new visitors will be randomly directed to one of them as a rough form of load balancing. If a session ID is present Simon will direct all further visits to the same destination. The session ID is read from the cookie "cookie_connect.sid" by default, see options below for how to change this.

### Wildcard domains

You can use an asterisk "\*" to define a catch-all / fallback for a single domain level. "*.example.dev" will match "hello.example.dev" but not "api.staging.example.dev":

```
> redis-cli sadd backends:*.example.dev 127.0.0.1:8080
1

> curl ww3.example.dev
<h1>Welcome to example.dev</h1>
```

If an exact match is found it will be used before a wildcard domain.

### Custom proxy hostname

Some proxied-to servers require a specific hostname to complete the request (maybe you're proxying to a S3 bucket, or another simon instance). The default behavior is for simon to send the same host as the original request (e.g. `example.dev`) but this can be overridden by setting `backends:[hostname]:host`:

```
> redis-cli set backends:example.dev:host example-bucket.s3.amazonaws.com
```

## Installation

* Compile nginx with Lua support (e.g. with [OpenResty](http://openresty.org/en/download.html))

```
apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
tar -xzvf openresty-VERSION.tar.gz
cd openresty-VERSION/
./configure  --with-luajit --prefix=/opt/openresty
make && sudo make install
```

* Clone Simon into `/opt/openresty/lualib/`

```
cd /opt/openresty/lualib/
git clone http://github.com/spro/simon
```

* Edit `/opt/openresty/nginx/conf/nginx.conf` to add `lua_package_path` (outside of the server block) and the Simon configuration (inside the location block).

```
http {

    ...
    
    lua_package_path "/opt/openresty/lualib/resty/?.lua";

    server {
    
        location / {
            set $proxy_to "";
            set $proxy_host "";
            access_by_lua_file "/opt/openresty/lualib/simon/simon.lua";
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_pass http://$proxy_to$request_uri;
        }
        
        ...
        
    }
    
}
```

## Options

* `cookie_key` (default "cookie_connect.sid"): Name of the cookie from which a session ID should be read.

Usage: in the location block, before `access_by_lua_file`, add a line `set $cookie_key "custom_cookie_key";`

### TODO

* Custom error pages (shows generic Nginx error if no hostname matches)
