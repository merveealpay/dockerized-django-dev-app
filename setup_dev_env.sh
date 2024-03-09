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
# Nginx configuration content (unchanged)
EOF

openssl req -x509 -newkey rsa:4096 -keyout nginx/key.pem -out nginx/cert.pem -days 365 -nodes -subj "/CN=localhost"

docker-compose up -d

echo "App is ready!! http://localhost to access."
