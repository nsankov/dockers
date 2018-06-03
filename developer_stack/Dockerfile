FROM php:7.2-apache
RUN a2enmod vhost_alias
RUN a2enmod rewrite
#RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql  && docker-php-ext-enable pdo_mysql
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
#RUN phpenmod pdo_mysql
COPY 000-default.conf /etc/apache2/sites-enabled/
