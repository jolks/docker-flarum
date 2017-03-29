FROM php:7.1.3-fpm-alpine

LABEL description "Next-generation forum software that makes online discussion fun" \
      maintainer="Hardware <hardware@mondedie.fr>, Magicalex <magicalex@mondedie.fr>"

ARG VERSION=v0.1.0-beta.6

# ENV GID=991 UID=991
# Temporary
ENV GID=root UID=root

RUN echo "@testing https://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
 && apk -U add --update \
    nginx \
    s6 \
    su-exec \
    curl \
    libpng-dev \
 && docker-php-ext-install mbstring pdo_mysql gd \
 && cd /tmp \
 && curl -s http://getcomposer.org/installer | php \
 && mv /tmp/composer.phar /usr/bin/composer \
 && chmod +x /usr/bin/composer \
 && mkdir -p /flarum/app \
 && chown -R $UID:$GID /flarum \
 && COMPOSER_CACHE_DIR="/tmp" su-exec $UID:$GID composer create-project flarum/flarum /flarum/app $VERSION --stability=beta \
 # ----- Zend stratigility deprecated message temporary fix -----
 # https://github.com/flarum/core/issues/1065
 && rm -f /flarum/app/composer.lock \
 && COMPOSER_CACHE_DIR="/tmp" su-exec $UID:$GID composer require zendframework/zend-stratigility:1.2.* -d /flarum/app \
 # --------------------------------------------------------------
 && composer clear-cache \
 && rm -rf /flarum/.composer /var/cache/apk/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/php7/php-fpm.conf
COPY opcache.ini /etc/php7/conf.d/00_opcache.ini
COPY config.php /flarum/app/config.php
COPY extension /usr/local/bin/extension
COPY s6.d /etc/s6.d
COPY run.sh /usr/local/bin/run.sh

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

VOLUME /flarum/app/assets /flarum/app/extensions

EXPOSE 8888

WORKDIR /flarum/app

CMD ["run.sh"]
