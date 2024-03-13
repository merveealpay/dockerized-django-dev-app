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
upstream web {
    server web:8000;
}

    server {

        location / {
            resolver 127.0.0.11;
            proxy_pass http://web;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $host;
            proxy_redirect off;
        }

        location /static/ {
            alias /static/;
        }
        location /media/ {
            alias /media/;
        }


  server {
    if ($host = pyeditorial.local) {
        return 301 https://$host$request_uri;
    }

        listen 80;
        server_name pyeditorial.local;
    return 404;
}
EOF

docker-compose up -d
