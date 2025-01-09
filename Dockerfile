FROM php:8.3.15-apache as php

LABEL maintainer "Mikkel Albrechtsen <me@themikkel.dk>"

# Handle Version
ARG VERSION="Development"
ENV VERSION=${VERSION}

# Set the working directory
WORKDIR /var/www/html

# Apache configuration
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
WORKDIR /var/www/html

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
	&& sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
	&& a2enmod rewrite

# Apache setup
RUN apt-get install libapache2-mod-security2 libapache2-mod-evasive git curl -y ;\
	mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf ;\
	sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf ; \
	sed -i "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf \
	a2enmod headers ;\
	mkdir /var/log/mod_evasive ;\
	chown -R www-data:www-data /var/log/mod_evasive

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install node and NPM
RUN apt-get -qq update && apt-get install -y \
	gnupg2 \
	lsb-release \
	&& curl -sL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get install -y nodejs \
	&& npm install -g npm@latest \
	&& mkdir -p /.npm \
	&& chown -R www-data:www-data /.npm \
	&& rm -r /var/lib/apt/lists/*;

# Apps
RUN apt-get -qq update && apt-get install -y \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
	zlib1g-dev libicu-dev g++\
	zip libzip-dev git \
	libcurl4-openssl-dev pkg-config libssl-dev ; \
	rm -r /var/lib/apt/lists/*;

# PHP Extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg > /dev/null  \
	&& docker-php-ext-install -j$(nproc) gd > /dev/null \
	&& docker-php-ext-configure intl > /dev/null \
	&& docker-php-ext-install intl > /dev/null \
	&& docker-php-ext-install zip > /dev/null \
	&& docker-php-ext-install pcntl > /dev/null \
	&& docker-php-ext-install mysqli pdo_mysql bcmath ctype > /dev/null \
	&& pecl install mongodb && docker-php-ext-enable mongodb > /dev/null

# Use the default php production configuration and set memory to 1024MB
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
	&& sed -i 's/memory_limit = .*/memory_limit = 1024M/' "$PHP_INI_DIR/php.ini" \
	&& sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$PHP_INI_DIR/php.ini" \
	&& sed -i 's/post_max_size = .*/post_max_size = 100M/' "$PHP_INI_DIR/php.ini" \
	&& sed -i 's/;opcache.enable=1/opcache.enable=1/' "$PHP_INI_DIR/php.ini" \
	&& sed -i 's/;expose_php = On/expose_php = Off/' "$PHP_INI_DIR/php.ini" \
	echo "\nServerName 127.0.0.1" >> /etc/apache2/apache2.conf; \
	echo "\nServerSignature Off\nServerTokens Prod\nFileETag None" >> /etc/apache2/apache2.conf

# Set the timezone
ARG TZ
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create symlink for public folder to the storage folder
RUN mkdir -p /var/www/html/public && \
	mkdir -p /var/www/html/storage/app/public && \
	ln -s /var/www/html/public /var/www/html/storage/app/public

# Add and set user
RUN useradd -ms /bin/bash app
USER app
