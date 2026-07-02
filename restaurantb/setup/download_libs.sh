#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
echo "Using temp directory: $TEMP_DIR"
cd "$TEMP_DIR"

# 1. Download Flight PHP
echo "Downloading Flight PHP..."
curl -L -o flight.zip https://github.com/flightphp/core/archive/refs/tags/v3.10.1.zip
unzip flight.zip
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/flight
cp -R core-3.10.1/flight/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/flight/

# 2. Download Plates
echo "Downloading Plates..."
curl -L -o plates.zip https://github.com/thephpleague/plates/archive/refs/tags/v3.4.0.zip
unzip plates.zip
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/plates
cp -R plates-3.4.0/src/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/plates/

# 3. Download Delight Auth and dependencies
echo "Downloading Delight Auth..."
curl -L -o auth.zip https://github.com/delight-im/PHP-Auth/archive/refs/heads/master.zip
unzip auth.zip

curl -L -o cookie.zip https://github.com/delight-im/PHP-Cookie/archive/refs/heads/master.zip
unzip cookie.zip

curl -L -o db.zip https://github.com/delight-im/PHP-DB/archive/refs/heads/master.zip
unzip db.zip

curl -L -o base64.zip https://github.com/delight-im/PHP-Base64/archive/refs/heads/master.zip
unzip base64.zip

# Create libraries directory structure for Delight
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Auth
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Cookie
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Db
mkdir -p /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Base64

# Copy src contents
cp -R PHP-Auth-master/src/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Auth/
cp -R PHP-Cookie-master/src/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Cookie/
cp -R PHP-DB-master/src/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Db/
cp -R PHP-Base64-master/src/* /home/carlos/GitHub/caelitandem_home/restaurantb/www/restaurant/commons/libs/auth/Delight/Base64/

# Clean up
rm -rf "$TEMP_DIR"
echo "All libraries downloaded and extracted successfully."
