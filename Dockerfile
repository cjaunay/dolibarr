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

# Copie le code source de Dolibarr
COPY ./dock_dolibarr /var/www/html

# Change les permissions du dossier
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 755 /var/www/html

RUN touch htdocs/conf/conf.php
RUN chown www-data:www-data htdocs/conf/conf.php
