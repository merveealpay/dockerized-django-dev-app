#!/bin/bash

git clone https://github.com/mavenium/PyEditorial.git pyeditorial_project
cd pyeditorial_project

sed -i '' 's/asgiref==3.3.1/asgiref>=3.3.2/' Dockerfile

sed -i '' 's/asgiref==3.3.1/asgiref>=3.3.2/' requirements.txt
echo "gunicorn" >> requirements.txt

cat << EOF > docker-compose.yml
version: '3.6'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: gunicorn PyEditorial.wsgi:application -w 4 -b 0.0.0.0:8000
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
    volumes:
      - ./nginx:/etc/nginx/conf.d
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web
EOF

mkdir nginx
cat <<EOF >nginx/default.conf
server {
    listen 80;
    listen [::]:80;
    return 301 https://pyeditorial$request_uri;
}

server {
	listen [::]:443 ssl ipv6only=on;
	listen 443 ssl;
	server_name pyeditorial;

	ssl_certificate /etc/nginx/conf.d/cert.pem;
    ssl_certificate_key /etc/nginx/conf.d/key.pem;

	location = /favicon.ico { access_log off; log_not_found off; }

	location / {
		proxy_pass		http://web:8000;
		proxy_redirect		off;

		proxy_set_header 	Host $http_host;
		proxy_set_header	X-Real-IP	$remote_addr;
		proxy_set_header	X-Forwarded-For	$proxy_add_x_forwarded_for;
		proxy_set_header	X-Forwarded-Proto	https;
	}
}
EOF

openssl req -x509 -newkey rsa:4096 -keyout nginx/key.pem -out nginx/cert.pem -days 365 -nodes -subj "/CN=pyeditorial"

docker-compose up -d

echo "App is ready!! https://localhost to access."
