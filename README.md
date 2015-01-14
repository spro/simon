# simon
Nginx Lua + Redis module for consistent routing to backend servers by session ID. Inspired by hipache.

## Adding a backend

```
redis sadd backends:[host] [ip]:[port]
```
