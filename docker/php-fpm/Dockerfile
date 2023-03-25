FROM php:8.2.4-fpm

LABEL author="Enzo Tarrery <tarrery.enzo@gmail.com>"

ARG UID
ARG USERNAME

# We set the max execution time to 2min
RUN touch /usr/local/etc/php/conf.d/max.ini && echo "max_execution_time = 120;" >> /usr/local/etc/php/conf.d/max.ini

# We set the env vars concerning the potential proxy
ENV http_proxy ${http_proxy}
ENV https_proxy ${http_proxy}

RUN apt update && apt install apt-utils

# We install git
RUN apt install -y git

# We install composer
COPY --from=composer:2.5.4 /usr/bin/composer /usr/local/bin/composer

# We install NodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# We install Symfony
RUN curl -sS https://get.symfony.com/cli/installer | bash

# We install Laravel CLI
RUN composer global require laravel/installer

# We add ourselves as user
# RUN useradd -mu ${UID} ${USERNAME}

# We precise the work directory
WORKDIR /var/www/apps/
