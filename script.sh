#!/bin/bash

# region: Env variables
# Charger les variables d'environnement du fichier .env
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | awk '/=/ {print $1}' | xargs)
else
  echo "Le fichier .env n'existe pas."
  exit 1
fi
# endregion: Env variables


# Message de bienvenue
echo "Bienvenue dans le script de création d'instance de Dolibarr."
echo "Ce script vous guidera pour créer une instance de Dolibarr pour une entreprise spécifique."
echo


# region: COMPANY_NAME #
read -p "- Nom de l'entreprise: " COMPANY_NAME

# Vérifier si le nom de l'entreprise est vide
if [ -z "$COMPANY_NAME" ]; then
  echo
  echo "Erreur: Le nom de l'entreprise ne peut pas être vide."
  exit 1
fi
# Vérifier si le nom de l'entreprise existe déjà
if [ -d "$COMPANY_NAME" ]; then
  echo
  echo "Erreur: Le nom de l'entreprise '$COMPANY_NAME' existe déjà."
  exit 1
fi
# Vérifier si le nom de l'entreprise ne contient que des lettres, des chiffres et des tirets haut et bas
if [[ ! "$COMPANY_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo
  echo "Erreur: Le nom de l'entreprise ne peut contenir que des lettres, des chiffres et des tirets."
  exit 1
fi

# if COMPANY_NAME contains '-' replace it with '_' to avoid error in database name
COMPANY_NAME_UNDERSCORE=$(echo $COMPANY_NAME | sed 's/-/_/g')
# endregion: COMPANY_NAME #


# region: MARIADB_ROOT_PASSWORD
MARIADB_ROOT_PASSWORD=$(openssl rand -base64 15) # Generate random password

# Affiche password
echo "- Le mot de passe de l'utilisateur root de la base de données sera '$MARIADB_ROOT_PASSWORD'."
read -p "- - Confirmez-vous? [y/n]" confirm

# # Si la confirmation est différente de 'y', demander le mot de passe
if [ "$confirm" != "y" ]; then
  read -p "- - - Mot de passe de l'utilisateur root: " MARIADB_ROOT_PASSWORD
fi
# endregion: MARIADB_ROOT_PASSWORD


# region: MYSQL_DATABASE #
MYSQL_DATABASE=dolibarr_${COMPANY_NAME_UNDERSCORE}

# Affiche le nom de la base de données et demande confirmation
echo "- Le nom de la base de données sera '$MYSQL_DATABASE'."
read -p "- - Confirmez-vous? [y/n]" confirm

# Si la confirmation est différente de 'y', demander le nom de la base de données
if [ "$confirm" != "y" ]; then
  read -p "- - - Nom de la base de données: " MYSQL_DATABASE
fi
# endregion: MYSQL_DATABASE #


# region: MYSQL_USER #
MYSQL_USER=dolibarr_${COMPANY_NAME_UNDERSCORE}

# Affiche le nom d'utilisateur de la base de données et demande confirmation
echo "- Le nom d'utilisateur de la base de données sera '$MYSQL_USER'."
read -p "- - Confirmez-vous? [y/n]" confirm

# Si la confirmation est différente de 'y', demander le nom d'utilisateur
if [ "$confirm" != "y" ]; then
  read -p "- - - Nom d'utilisateur de la base de données: " MYSQL_USER
fi
# endregion: MYSQL_USER #


# region: MYSQL_PASSWORD #
MYSQL_PASSWORD=$(openssl rand -base64 15) # Generate random password

# Affiche le mot de passe de l'utilisateur de base et demande confirmation
echo "- Le mot de passe de l'utilisateur de la base de données sera '$MYSQL_PASSWORD'."
read -p "- - Confirmez-vous? [y/n]" confirm

# # Si la confirmation est différente de 'y', demander le mot de passe
if [ "$confirm" != "y" ]; then
  read -p "- - - Mot de passe de l'utilisateur de la base de données: " MYSQL_PASSWORD
fi
# endregion: MYSQL_PASSWORD #


# region: DOLI_ADMIN_LOGIN
echo "- Le login SuperAdmin de Dolibarr sera '$DOLI_ADMIN_LOGIN'."
read -p "- - Confirmez-vous? [y/n]" confirm

# Si la confirmation est différente de 'y', demander le mot de passe
if [ "$confirm" != "y" ]; then
  read -p "- - - Login SuperAdmin de Dolibarr: " DOLI_ADMIN_LOGIN
fi
# endregion: DOLI_ADMIN_LOGIN


# region: DOLI_ADMIN_PASSWORD
DOLI_ADMIN_PASSWORD=$(openssl rand -base64 15) # Generate random password

echo "- Le mot de passe du SuperAdmin sera '$DOLI_ADMIN_PASSWORD'."
read -p "- - Confirmez-vous? [y/n]" confirm

# # Si la confirmation est différente de 'y', demander le mot de passe
if [ "$confirm" != "y" ]; then
  read -p "- - - Mot de passe du SuperAdmin: " DOLI_ADMIN_PASSWORD
fi
# endregion: DOLI_ADMIN_PASSWORD


# region : TRAEFIK_HOST & URL
TRAEFIK_HOST=${COMPANY_NAME}.timesaving.fr
URL="https://${TRAEFIK_HOST}"
# endregion : TRAEFIK_HOST & URL


# region: folders
# Création du dossier spécifique à l'entreprise
mkdir $COMPANY_NAME && cd $COMPANY_NAME

mkdir custom && mkdir documents && mkdir mariadb
# endregion: folders


# region: compose.yml
# Génération du fichier compose.yml
cat <<EOF > compose.yml
services:
  dolibarr:
    container_name: dolibarr_${COMPANY_NAME_UNDERSCORE}
    image: dolibarr/dolibarr:20
	env
    environment:
      - DOLI_DB_HOST=$DOLI_DB_HOST
      - DOLI_DB_NAME=$MYSQL_DATABASE
      - DOLI_DB_USER=$MYSQL_USER
      - DOLI_DB_PASSWORD=$MYSQL_PASSWORD
      - DOLI_ADMIN_LOGIN=$DOLI_ADMIN_LOGIN
      - DOLI_ADMIN_PASSWORD=$DOLI_ADMIN_PASSWORD
      - DOLI_INIT_DEMO=0
      - WWW_USER_ID=$WWW_USER_ID
      - WWW_GROUP_ID=$WWW_GROUP_ID
      - DOLI_COMPANY_NAME=$COMPANY_NAME
      - DOLI_COMPANY_COUNTRYCODE=FR
    links:
      - mariadb
    volumes:
      - dolibarr-custom:/var/www/html/custom
      - dolibarr-documents:/var/www/documents
      - ./custom:/var/www/html/custom
      - ./documents:/var/www/documents
    labels:
      - traefik.enable=true
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.entrypoints=web
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.entrypoints=websecure
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.tls=true
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.tls.certresolver=production
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.rule=Host(\`$TRAEFIK_HOST\`)
      - traefik.http.services.website.loadbalancer.server.port=80
    networks:
      - traefik_default
    restart: always

  mariadb:
    container_name: mariadb_${COMPANY_NAME_UNDERSCORE}
    image: mariadb:latest
    environment:
      - MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
      - MYSQL_DATABASE=$MYSQL_DATABASE
      - MYSQL_USER=$MYSQL_USER
      - MYSQL_PASSWORD=$MYSQL_PASSWORD
    volumes:
      - mariadb-db:/var/lib/mysql
      - ./mariadb:/var/lib/mysql
    networks:
      - traefik_default

networks:
  traefik_default:
    external: true

volumes:
  mariadb-db:
  dolibarr-custom:
  dolibarr-documents:
EOF
# endregion: compose.yml


docker compose up --build -d

# Message de confirmation
echo "Le fichier 'compose.yml' pour l'entreprise '$COMPANY_NAME' a été créé et lancé avec succès."



# Summary
echo "Résumé:"
echo "Nom de l'entreprise: $COMPANY_NAME / $COMPANY_NAME_UNDERSCORE"
echo "URL: $URL"
echo "Identifiant de l'administrateur: $DOLI_ADMIN_LOGIN"
echo "Mot de passe de l'administrateur: $DOLI_ADMIN_PASSWORD"
echo "Nom de la base de données: $MYSQL_DATABASE"
echo "Nom d'utilisateur de la base de données: $MYSQL_USER"
echo "Mot de passe de la base de données: $MYSQL_PASSWORD"
