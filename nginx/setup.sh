#!/usr/bin/env bash

sudo apt update
sudo apt install nginx certbot python3-certbot-nginx


sudo -u enfuser mkdir -p /home/enfuser/www/html/testnet-1
cd /local/VaultaFoundation/repos/bootstrap-private-network/nginx

for site in testnet testnet-1 api.testnet-1 p2p.testnet-1
do
	sudo cp sites-available/${site}.vaulta.com /etc/nginx/sites-available/${site}.vaulta.com
	sudo ln -s /etc/nginx/sites-available/${site}.vaulta.com /etc/nginx/sites-enabled/
done

sudo -u enfuser cp html/landing/index.html /home/enfuser/www/html/
sudo -u enfuser cp html/testnet/index.html /home/enfuser/www/html/testnet-1/

LANDING_DOMAIN=testnet.valuta.com
LANDING_TESTNET_1=testnet-1.vaulta.com
API_TESTNET_1=api.testnet-1.vaulta.com
P2P_TESTNET_1=p2p.testnet-1.vaulta.com
UNICOVE_TESTNET_1=unicove.testnet-1.vaulta.com

# OPEN FIREWALL PORT 80 and 443
# Check your DNS even just a landing page is ok
# NO cert just HTTP
for domain in $LANDING_DOMAIN $LANDING_TESTNET_1 $API_TESTNET_1 $P2P_TESTNET_1 $UNICOVE_TESTNET_1
do
	curl http://${domain}
	if [ $? != 0 ]; then 
		echo "ERROR: can't reach http://${domain}"
		exit 1
	fi
done

sudo certbot --nginx -d $LANDING_DOMAIN -d $LANDING_TESTNET_1 -d $API_TESTNET_1 -d $P2P_TESTNET_1 -d $UNICOVE_TESTNET_1
sudo certbot renew --dry-run

# CLOSE PORT 80
sudo nginx -t
if [[ $? == 0 ]]; then 
	sudo systemctl reload nginx
fi
# python code for flask app
pip install flask gunicorn
# later gunicorn --bind 127.0.0.1:5000 app:application