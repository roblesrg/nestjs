#!/bin/bash

# Verificar si se proporcionó un nombre de proyecto
if [ -z "$1" ]; then
  echo "Error: Debes proporcionar un nombre para el proyecto."
  echo "Uso: ./crear-proyecto-nest.sh <nombre-del-proyecto>"
  exit 1
fi

# Nombre del proyecto
PROJECT_NAME=$1

# Seleccionar paquete
echo "¿Qué gestor de paquetes deseas usar?"
echo "1) npm"
echo "2) yarn"
echo "3) pnpm"
read -p "Selecciona una opción (1-3): " PACKAGE_MANAGER_CHOICE

# Asignación de paquete
case $PACKAGE_MANAGER_CHOICE in
  1)
    PACKAGE_MANAGER="npm"
    ;;
  2)
    PACKAGE_MANAGER="yarn"
    ;;
  3)
    PACKAGE_MANAGER="pnpm"
    ;;
  *)
    echo "Opción no válida. Usando npm por defecto."
    PACKAGE_MANAGER="npm"
    ;;
esac

echo "Creando proyecto NestJS: $PROJECT_NAME con $PACKAGE_MANAGER..."

# Comando para crear el proyecto NestJS
docker run --rm -v $(pwd):/app -w /app node:lts sh -c "npm install -g @nestjs/cli && nest new $PROJECT_NAME --strict --package-manager $PACKAGE_MANAGER"

# Verificar si el proyecto se creó correctamente
if [ ! -d "$PROJECT_NAME" ]; then
  echo "Error: No se pudo crear el proyecto $PROJECT_NAME."
  exit 1
fi

echo "Proyecto $PROJECT_NAME creado correctamente."

# Cambiar los permisos de los archivos creados
echo "Cambiando permisos de los archivos..."
sudo chown -R $USER:$USER $PROJECT_NAME

# Acceder al directorio para la creación del dockerfile y docker-compose
cd $PROJECT_NAME

# Dockerfile
cat <<EOL > Dockerfile
FROM node:lts

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN chown -R node:node /app/node_modules

USER node

CMD ["npm", "run", "start:dev"]
EOL

# docker-compose.yml
# Configurar para la conexión de la base de datos
cat <<EOL > docker-compose.yml
services:
  app:
    container_name: app
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      NODE_ENV: development
    tty: true
EOL

echo "Proyecto $PROJECT_NAME configurado con Docker."
