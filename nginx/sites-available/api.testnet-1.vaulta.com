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
        proxy_pass http://apibackend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
