#!/bin/bash

# Define variables
NGINX_CONFIG="/etc/nginx/sites-available/default"
PHP_VERSION="php8.4" # Adjust according to your PHP version
FPM_SOCK="/var/run/php/${PHP_VERSION}-fpm.sock"

# Function to install necessary packages
install_packages() {
    sudo apt update
    sudo apt install -y nginx $PHP_VERSION-fpm curl
}

# Function to generate a random alphabetical word
generate_random_word() {
    local word=$(head /dev/urandom | tr -dc A-Za-z | head -c 5)
    echo "$word"
}

# Function to download and install Adminer
download_adminer() {
    local adminer_url="https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php"
    local temp_file="/tmp/adminer.php"
    local random_word=$(generate_random_word)
    local renamed_file="/var/www/html/${random_word}.php"

    # Download Adminer
    curl -o "$temp_file" -L "$adminer_url"

    # Rename the file to a random word and move to destination
    sudo mv "$temp_file" "$renamed_file"
}

# Function to configure Nginx
configure_nginx() {
    sudo tee $NGINX_CONFIG > /dev/null <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$FPM_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
}

# Function to test and restart Nginx configuration
reload_nginx() {
    sudo nginx -t && sudo systemctl restart nginx
}

# Main script execution
install_packages
download_adminer
configure_nginx
reload_nginx

echo "Nginx configured to serve PHP files. You can access Adminer at http://your-ip-address/<random_word>.php"
