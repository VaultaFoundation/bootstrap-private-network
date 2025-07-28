upstream apibackend {
    server 127.0.0.1:8888;
    server 127.0.0.1:7888;
}

server {
    listen 80;
    server_name api.testnet-1.vaulta.com;
    
    # Block /v*/net/ pattern
    location ~ ^/v[0-9]+/net(/.*)?$ {
        return 403;
    }

    location / {
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
            return 204;
        }

        proxy_pass http://apibackend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept" always;
    }
}


