FROM php:8.2.0-apache

# Installe les modules PHP requis
RUN apt-get update -y
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev libzip-dev libc-client-dev libmcrypt-dev libkrb5-dev libonig-dev unzip wget git zlib1g-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl

RUN docker-php-ext-install -j$(nproc) gd calendar intl imap zip mysqli

# pdo \
# pdo_mysql \
# bcmath \
# bz2 \
# curl \
# json \
# mbstring \
# pear \
# readline \
# tcpdf \
# xml


# Télécharge et décompresse Dolibarr
# COPY ./dolibarr-20.0.0.zip /tmp/dolibarr.zip
# RUN cp ../dolibarr-20.0.0.zip /var/www/html

RUN wget https://sourceforge.net/projects/dolibarr/files/Dolibarr%20ERP-CRM/20.0.0/dolibarr-20.0.0.zip -O /tmp/dolibarr.zip
RUN unzip /tmp/dolibarr.zip -d /tmp

# Déplace tout le contenu de l'archive dans /var/www/html
RUN mv /tmp/dolibarr-20.0.0/* /var/www/html/

# Supprime les fichiers temporaires
RUN rm -rf /tmp/dolibarr-20.0.0 /tmp/dolibarr.zip


# Change les permissions du dossier
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 755 /var/www/html

# Définir /var/www/html comme répertoire de travail
WORKDIR /var/www/html

RUN touch htdocs/conf/conf.php
RUN chown www-data:www-data htdocs/conf/conf.php
