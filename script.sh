#!/bin/bash


# region: Ideas
# Fonction pour demander et valider une entrée utilisateur
# prompt_input() {
#     local prompt_message=$1
#     local validation_regex=$2

#     while true; do
#         read -p "${prompt_message}: " input
#         if [[ -z "$input" ]]; then
#             echo "Erreur: L'entrée ne peut pas être vide."
#         elif [[ ! "$input" =~ $validation_regex ]]; then
#             echo "Erreur: L'entrée ne correspond pas au format requis."
#         else
#             echo "$input"
#             break
#         fi
#     done
# }

# # Exemple d'utilisation pour le nom de l'entreprise
# COMPANY_NAME=$(prompt_input "Veuillez entrer le nom de l'entreprise" '^[a-zA-Z0-9_-]+$')

# # Valider si le dossier existe déjà
# if [ -d "$COMPANY_NAME" ]; then
#     echo "Erreur: Le nom de l'entreprise '${COMPANY_NAME}' existe déjà."
#     exit 1
# fi
# endregion: Ideas


# region: Functions
# # Fonction pour ajouter des couleurs
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# BLUE='\033[0;34m'
# NC='\033[0m' # No Color

# # Fonction pour afficher des lignes de séparation
# #echo -e "${BLUE}----------------------------------------${NC}"
# separator() {
# 	echo "----------------------------------------"
# }

# # Fonction pour afficher des messages d'erreur
# error() {
# 	echo -e "${RED}Erreur: $1${NC}"
# 	exit 1
# }

# # Fonction pour afficher des messages de succès
# success() {
# 	echo -e "${GREEN}Succès: $1${NC}"
# }

# # Fonction pour afficher des messages d'avertissement
# warning() {
# 	echo -e "${YELLOW}Avertissement: $1${NC}"
# }

# # Fonction pour afficher des messages d'information
# info() {
# 	echo -e "${BLUE}Information: $1${NC}"
# }

# # Fonction pour afficher des messages de débogage
# debug() {
# 	echo -e "${YELLOW}Débogage: $1${NC}"
# }

# # Fonction pour afficher des messages de confirmation
# confirm() {
# 	read -p "$1 [y/n]: " response
# 	case $response in
# 		[yY][eE][sS] | [yY])
# 			true
# 			;;
# 		*)
# 			false
# 			;;
# 	esac
# }
# endregion: Functions


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
read -p "- Veuillez entrer le nom de l'entreprise : " COMPANY_NAME

# Vérifier si le nom de l'entreprise est vide
if [ -z "${COMPANY_NAME}" ]; then
	echo "  Erreur: Le nom de l'entreprise ne peut pas être vide."
	exit 1
fi
# Vérifier si le nom de l'entreprise existe déjà
if [ -d "${COMPANY_NAME}" ]; then
	echo "  Erreur: Le nom de l'entreprise '${COMPANY_NAME}' existe déjà."
	exit 1
fi
# Vérifier si le nom de l'entreprise ne contient que des lettres, des chiffres et des tirets haut et bas
if [[ ! "${COMPANY_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
	echo "  Erreur: Le nom de l'entreprise ne peut contenir que des lettres, des chiffres et des tirets."
	exit 1
fi

# Remplacer les espaces et tirets par des underscores pour éviter des erreurs dans le nom de la base de données
COMPANY_NAME_UNDERSCORE=$(echo ${COMPANY_NAME} | sed 's/[ -]/_/g')
# endregion: COMPANY_NAME #


echo
echo
echo "###################################################"
echo "                    MARIADB                        "
echo "###################################################"

# region: MARIADB_ROOT_PASSWORD
MARIADB_ROOT_PASSWORD=$(openssl rand -base64 15) # Generate random password

# Afficher le mot de passe généré et demande confirmation
echo "- Le mot de passe de l'utilisateur root pour le serveur de bases de données a été généré."
echo "  Mot de passe: ${MARIADB_ROOT_PASSWORD}"
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# Si l'utilisateur ne confirme pas, demander un mot de passe personnalisé
if [ "$confirm" != "y" ]; then
	read -p "  Mot de passe de l'utilisateur root: " MARIADB_ROOT_PASSWORD

	if [ -z "${MARIADB_ROOT_PASSWORD}" ]; then
		echo "  Erreur: Le mot de passe de l'utilisateur root ne peut pas être vide."
		exit 1
	fi
fi
# endregion: MARIADB_ROOT_PASSWORD


# region: MYSQL_DATABASE #
MYSQL_DATABASE=dolibarr_${COMPANY_NAME_UNDERSCORE}

# Affiche le nom de la base de données et demande confirmation
echo
echo "- Le nom de la base de données a été généré."
echo "  Nom de la base de données: ${MYSQL_DATABASE}."
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# Si l'utilisateur ne confirme pas, demander le nom de la base de données
if [ "$confirm" != "y" ]; then
	read -p "  Nom de la base de données: " MYSQL_DATABASE

	if [ -z "${MYSQL_DATABASE}" ]; then
		echo "  Erreur: Le nom de la base de données ne peut pas être vide."
		exit 1
	fi
fi
# endregion: MYSQL_DATABASE #


# region: MYSQL_USER #
MYSQL_USER=dolibarr_${COMPANY_NAME_UNDERSCORE}

# Affiche l'identifiant de l'utilisateur pour la base de données et demande confirmation
echo
echo "- L'identifiant de l'utilisateur pour la base de données a été généré."
echo "  Identifiant: ${MYSQL_USER}."
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# Si l'utilisateur ne confirme pas, demander l'identifiant de l'utilisateur
if [ "$confirm" != "y" ]; then
	read -p "  Identifiant: " MYSQL_USER

	if [ -z "${MYSQL_USER}" ]; then
		echo "  Erreur: L'identifiant de l'utilisateur ne peut pas être vide."
		exit 1
	fi
fi
# endregion: MYSQL_USER #


# region: MYSQL_PASSWORD #
MYSQL_PASSWORD=$(openssl rand -base64 15) # Generate random password

# Affiche le mot de passe de l'utilisateur et demande confirmation
echo
echo "- Le mot de passe de l'utilisateur ${MYSQL_USER} a été généré."
echo "  Mot de passe: ${MYSQL_PASSWORD}."
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# Si l'utilisateur ne confirme pas, demander le mot de passe
if [ "$confirm" != "y" ]; then
	read -p "  Mot de passe de l'utilisateur ${MYSQL_USER}: " MYSQL_PASSWORD

	if [ -z "${MYSQL_PASSWORD}" ]; then
		echo "  Erreur: Le mot de passe de l'utilisateur ${MYSQL_USER} ne peut pas être vide."
		exit 1
	fi
fi
# endregion: MYSQL_PASSWORD #


echo
echo
echo "###################################################"
echo "                    DOLIBARR                       "
echo "###################################################"

# region: DOLI_ADMIN_LOGIN
# Affiche l'identifiant de l'utilisateur SuperAdmin Dolibarr et demande confirmation
echo "- L'identifiant de l'utilisateur SuperAdmin pour Dolibarr a été généré."
echo "  Identifiant: ${DOLI_ADMIN_LOGIN}."
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# Si l'utilisateur ne confirme pas, demander l'identifiant de l'utilisateur SuperAdmin
if [ "$confirm" != "y" ]; then
	read -p " Identifiant: " DOLI_ADMIN_LOGIN

	if [ -z "${DOLI_ADMIN_LOGIN}" ]; then
		echo "  Erreur: L'identifiant de l'utilisateur SuperAdmin ne peut pas être vide."
		exit 1
	fi
fi
# endregion: DOLI_ADMIN_LOGIN


# region: DOLI_ADMIN_PASSWORD
DOLI_ADMIN_PASSWORD=$(openssl rand -base64 15) # Generate random password

# Affiche le mot de passe du SuperAdmin Dolibarr et demande confirmation
echo
echo "- Le mot de passe de l'utilisateur SuperAdmin pour Dolibarr a été généré."
echo "  Mot de passe: ${DOLI_ADMIN_PASSWORD}."
echo
read -p "  Confirmez-vous ? [y/n]: " confirm

# # Si la confirmation est différente de 'y', demander le mot de passe
if [ "$confirm" != "y" ]; then
	read -p "  Mot de passe de l'utilisateur SuperAdmin: " DOLI_ADMIN_PASSWORD

	if [ -z "${DOLI_ADMIN_PASSWORD}" ]; then
		echo "  Erreur: Le mot de passe de l'utilisateur SuperAdmin ne peut pas être vide."
		exit 1
	fi
fi
# endregion: DOLI_ADMIN_PASSWORD


# region : TRAEFIK_HOST & URL
TRAEFIK_HOST=${COMPANY_NAME}.timesaving.fr
URL="https://${TRAEFIK_HOST}"
# endregion : TRAEFIK_HOST & URL


# region: folders
# Création du dossier spécifique à l'entreprise
mkdir ${COMPANY_NAME} && cd ${COMPANY_NAME}

mkdir custom && mkdir documents && mkdir mariadb
# endregion: folders


# region: compose.yml
# Génération du fichier compose.yml
cat <<EOF > compose.yml
services:
  dolibarr:
    container_name: dolibarr_${COMPANY_NAME_UNDERSCORE}
    image: dolibarr/dolibarr:20
    environment:
      - DOLI_DB_HOST=${DOLI_DB_HOST}
      - DOLI_DB_NAME=${MYSQL_DATABASE}
      - DOLI_DB_USER=${MYSQL_USER}
      - DOLI_DB_PASSWORD=${MYSQL_PASSWORD}
      - DOLI_ADMIN_LOGIN=${DOLI_ADMIN_LOGIN}
      - DOLI_ADMIN_PASSWORD=${DOLI_ADMIN_PASSWORD}
      - DOLI_INIT_DEMO=0
      - WWW_USER_ID=${WWW_USER_ID}
      - WWW_GROUP_ID=${WWW_GROUP_ID}
      - DOLI_COMPANY_NAME=${COMPANY_NAME}
      - DOLI_COMPANY_COUNTRYCODE=FR
    links:
      - mariadb
    volumes:
      - ./custom:/var/www/html/custom
      - ./documents:/var/www/documents
    labels:
      - traefik.enable=true
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.entrypoints=web
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.entrypoints=websecure
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.tls=true
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.tls.certresolver=production
      - traefik.http.routers.${COMPANY_NAME_UNDERSCORE}.rule=Host(\`${TRAEFIK_HOST}\`)
      - traefik.http.services.${COMPANY_NAME_UNDERSCORE}.loadbalancer.server.port=80
    networks:
      - traefik_default
    restart: always

  mariadb:
    container_name: mariadb_${COMPANY_NAME_UNDERSCORE}
    image: mariadb:latest
    environment:
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./mariadb:/var/lib/mysql
    networks:
      - traefik_default
    restart: always

networks:
  traefik_default:
    external: true
EOF
# endregion: compose.yml


docker compose up --build -d

# Attendre quelques secondes pour s'assurer que les services sont en cours d'exécution
# sleep 10


# region: Summary
# Write summary to a file
cat <<EOF > summary.txt
Nom de l'entreprise: ${COMPANY_NAME}
Lien d'accès: ${URL}
Crédentials de l'administrateur: ${DOLI_ADMIN_LOGIN} / ${DOLI_ADMIN_PASSWORD}
Nom de la base de données: ${MYSQL_DATABASE}
Crédential de l'utilisateur de la base de données pour dolibarr: ${MYSQL_USER} / ${MYSQL_PASSWORD}
Crédential de l'utilisateur root de la base de données: root / ${MARIADB_ROOT_PASSWORD}
EOF

echo
echo
echo "###################################################"
echo "                    SUMMARY                        "
echo "###################################################"
echo "Un fichier contenant les informations a été créé."
echo "L'instance de Dolibarr et de MariaDB sont en cours de lancement."
echo "Vous pouvez accéder à Dolibarr à l'URL suivante :"
echo "${URL}"
# endregion: Summary
