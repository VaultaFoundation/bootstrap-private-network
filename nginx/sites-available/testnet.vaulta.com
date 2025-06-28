server {
    listen 80;
    server_name testnet.vaulta.com;

    root /home/enfuser/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
