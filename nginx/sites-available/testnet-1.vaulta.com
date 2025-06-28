server {
    listen 80;
    server_name testnet-1.vaulta.com;

    root /home/enfuser/www/html/testnet-1;
    index index.html;

    # Serve Flask under /service
    location /service {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Optional: handle WebSockets if Flask uses them
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location / {
        try_files $uri $uri/ =404;
    }
}

