FROM php:8.2.4-fpm

LABEL author="Enzo Tarrery <tarrery.enzo@gmail.com>"

ARG UID

# We set the max execution time to 2min
RUN touch /usr/local/etc/php/conf.d/max.ini && echo "max_execution_time = 120;" >> /usr/local/etc/php/conf.d/max.ini

# We set the env vars concerning the potential proxy
ENV http_proxy ${http_proxy}
ENV https_proxy ${http_proxy}

RUN apt-get update && \ 
    apt-get -y upgrade && \ 
    apt-get install -y sudo apt-utils zip git

# We install composer
COPY --from=composer:2.5.5 /usr/bin/composer /usr/local/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1

# We install Symfony
RUN curl -sS https://get.symfony.com/cli/installer | bash

# We install Laravel CLI
RUN composer global require laravel/installer

# We install NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs gcc g++ make && \
    npm install -g npm@latest && \
    npm install -g create-react-app@latest

# We install Angular CLI
RUN npm install -g @angular/cli

# We add ourselves as user
RUN useradd -mu ${UID} user

RUN echo "user  ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/user

USER user

# We precise the work directory
WORKDIR /var/www/apps/
