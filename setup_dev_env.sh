#!/bin/bash

git clone https://github.com/mavenium/PyEditorial.git pyeditorial_project
cd pyeditorial_project

# Update requirements
function update_requirements() {
    local file=$1
    local old_version=$2
    local new_version=$3

    sed -i '' "s/${old_version}/${new_version}/" "${file}"
}

update_requirements "Dockerfile" "asgiref==3.3.1" "asgiref>=3.3.2"
update_requirements "requirements.txt" "asgiref==3.3.1" "asgiref>=3.3.2"

echo "gunicorn" >> requirements.txt

mkdir -p ./certbot/conf
mkdir -p ./certbot/www
chmod -R 777 ./certbot/conf
chmod -R 777 ./certbot/www

cat << EOF > docker-compose.yml
version: '3.6'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: gunicorn PyEditorial.wsgi:application -w 4 -b 0.0.0.0:8000
    extra_hosts:
      - "pyeditorial.local:127.0.0.1"
    volumes:
      - ./:/code
    ports:
      - '8000:8000'
    depends_on:
      - postgres

  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydatabase

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done'"
    depends_on:
      - nginx

  nginx:
    image: nginx:latest
    extra_hosts:
      - "pyeditorial.local:127.0.0.1"
    ports:
      - "80:80"
      - "443:443"
    restart: always
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - web
EOF

mkdir nginx
cat <<EOF >nginx/default.conf
server {
    listen 80;
    server_name pyeditorial.local;
    location / {
        return 301 https://$host$request_uri;
    }
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl;
    server_name pyeditorial.local;

    ssl_certificate /etc/letsencrypt/live/pyeditorial.local/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pyeditorial.local/privkey.pem;

    location / {
        proxy_pass http://web;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
    }
}
EOF

docker-compose up -d
