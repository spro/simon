# simon
Dynamic routing / virtual hosts with nginx, Lua, and Redis.

Simon allows you to very quickly point domains to specific hosts and ports by defining `proxy_pass` directives in Redis. Largely inspired by [hipache](https://github.com/hipache/hipache), a standalone proxy that does the same thing.

![simon](https://github.com/spro/simon/blob/master/simon.png?raw=true)

## Usage

For every request(!), Simon looks up the Redis Set `simon:[hostname]` to find one or more destinations. To define a route, add a destination (`ip` or `ip:port` or even `hostname/path`) to a Redis set `simon:[route]`:

```
> redis-cli sadd simon:example.dev 127.0.0.1:5555
> redis-cli sadd simon:api.example.dev 144.244.222.111
> redis-cli sadd simon:static.example.dev bucket.s3-website.amazonaws.com/folder
```

Wait, for every request? Isn't that slow? Not at all, we're talking Nginx and Redis here.

### Basic example

Point `example.dev` to local port 8080:

```
> redis-cli sadd simon:example.dev 127.0.0.1:8080
1

> curl example.dev
<h1>Welcome to example.dev</h1>
```

### Load balancing example

Distribute requests for `api.example.dev` to ports 5566 and 5577:

```
> redis-cli sadd simon:api.example.dev 127.0.0.1:5566 127.0.0.1:5577
2

> curl api.example.dev
{"success": "definitely"}
```

If Simon finds multiple destinations, new visitors will be randomly directed to one of them as a rough form of load balancing. If a session ID is present Simon will direct all further visits to the same destination. The session ID is read from the cookie "cookie_connect.sid" by default, see options below for how to change this.

## Installation

These instructions are specific to the [OpenResty](http://openresty.org/en/download.html) distribution on Ubuntu:

* Download and compile nginx with Lua support

```bash
# probably as sudo
apt-get update
apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
curl -LO https://openresty.org/download/openresty-1.11.2.2.tar.gz
tar -xzvf openresty-1.11.2.2.tar.gz
cd openresty-1.11.2.2/
./configure  --with-luajit --prefix=/opt/openresty
make && make install
```

* Clone Simon into `/opt/openresty/lualib/`

```bash
# still as sudo
cd /opt/openresty/lualib/
git clone http://github.com/spro/simon
```

* Edit `/opt/openresty/nginx/conf/nginx.conf` to add `lua_package_path` (outside the `server` block) and the Simon configuration (inside the server `location` block):

```conf
http {

    # ...
    
    lua_package_path "/opt/openresty/lualib/resty/?.lua"; # Include Lua libraries

    server {
    
        # Pass all requests through Simon
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
        
        # ...
        
    }
    
}
```

The above config first initializes Nginx variables `$proxy_to` and `$proxy_host` (to make them available in the Lua scope) then runs Simon, then uses those (now defined) variables to set up the `proxy_pass` directive.

## Other features

### Wildcard domains

You can use an asterisk "\*" to define a catch-all / fallback *for a single level of subdomain*. For example, "*.example.dev" will match "hello.example.dev" but not "api.staging.example.dev":

```
> redis-cli sadd simon:*.example.dev 127.0.0.1:8080
1

> curl ww3.example.dev
<h1>Welcome to example.dev</h1>
```

Wildcard domains are only used if an exact match is not found.

### Setting a specific hostname

Some proxied-to servers require a specific hostname to understand the request (maybe you're proxying to a S3 bucket, Wordpress instance, or another Simon instance). By default Simon copies the hostname of the original request (so if the request is to `example.dev`, that will be carried along in the proxied request). To send a specific hostname, you can define a "`:hostname`" key:

`SET simon:[route]:hostname [hostname]`

#### Example: Proxying to a S3 website

Set up "Static website hosting" on your S3 bucket to get public access and loading index.html for / requests.

```
> redis-cli sadd simon:static.example.dev bucket.s3-website.amazonaws.com/folder
> redis-cli set simon:static.example.dev:hostname bucket.s3-website.amazonaws.com
```

## TODO

* Non-proxy routes e.g. `backends:static.example.dev /var/nginx/html/static`
* Custom error pages (currently shows a generic Nginx error if no hostname matches)
