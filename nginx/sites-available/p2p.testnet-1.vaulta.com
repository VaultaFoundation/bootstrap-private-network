upstream p2pbackend {
    server 127.0.0.1:1444;
    server 127.0.0.1:2444;
}

server {
    listen 80;
    server_name p2p.testnet-1.vaulta.com;

    location / {
        proxy_pass http://p2pbackend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
