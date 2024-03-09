#!/bin/bash

# Set variables
PROJECT_NAME="pyeditorial"
APP_PORT=8000
NGINX_PORT=80
NGINX_HTTPS_PORT=443

# Clone the PyEditorial repository
git clone https://github.com/mavenium/PyEditorial.git $PROJECT_NAME
cd $PROJECT_NAME

mkdir -p nginx

# Create a self-signed SSL certificate
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out nginx/cert.pem -keyout nginx/cert.key -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set up a virtual environment
python3 -m venv venv
source venv/bin/activate

chmod +w requirements.txt

# Update requirements.txt to resolve dependencies
#sed -i 's/asgiref==3.3.1/asgiref>=3.3.2/' requirements.txt
#echo "asgiref>=3.3.2" > requirements.txt
sed -i '' 's/asgiref==3.3.1/asgiref>=3.3.2/' requirements.txt
echo "gunicorn>=21.0.0" >> requirements.txt

cat requirements.txt
# Install dependencies
pip install -r requirements.txt

# Create a docker-compose.yml file
cat <<EOF > docker-compose.yml
version: '3'
services:
  postgres_1:
    image: postgres
    environment:
      POSTGRES_DB: pyeditorial_db
      POSTGRES_USER: pyeditorial_user
      POSTGRES_PASSWORD: pyeditorial_password

  web_1:
    build:
      context: .
      dockerfile: Dockerfile
    command: gunicorn PyEditorial.wsgi:application -b 0.0.0.0:$APP_PORT
    volumes:
      - ./PyEditorial:/app
    expose:
      - $APP_PORT
    depends_on:
      - postgres_1
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:$APP_PORT/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  nginx_1:
    image: nginx
    volumes:
      - ./nginx:/etc/nginx/conf.d
      - ./nginx/cert.pem:/etc/nginx/cert.pem
      - ./nginx/cert.key:/etc/nginx/cert.key
    ports:
      - $NGINX_PORT:80
      - $NGINX_HTTPS_PORT:443
    depends_on:
      - web_1
EOF


# Build and start the Docker containers
docker-compose up --build -d

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
sleep 50

# Run database migrations
docker-compose exec web python manage.py migrate

echo "Development environment is ready."
echo "You can access the PyEditorial app at http://localhost:$APP_PORT"
echo "For HTTPS, use https://localhost:$NGINX_HTTPS_PORT"

# End of script
