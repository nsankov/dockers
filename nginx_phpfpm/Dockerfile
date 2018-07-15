FROM php:5.6-fpm
RUN chmod +x /entrypoint.sh
RUN apt-get update \
     && apt-get install -y \
        unzip \
        net-tools \
         libssl-dev \
         libmemcached-dev \
         libpq-dev \
         libxml2 \
         libxml2-dev \
         zlib1g-dev \
     && pecl install memcached-2.2.0 \
     && pecl install memcache
RUN docker-php-ext-enable memcached \
    && docker-php-ext-enable memcache
