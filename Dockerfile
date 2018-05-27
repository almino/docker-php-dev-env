FROM ubuntu:16.04

# We need this to install stuff
RUN apt-get update

# https://github.com/webdevops/Dockerfile/blob/ba5ae50ab00779771addbb5171a0cef7d75250c6/docker/php-official/5.6/Dockerfile#L37
# We'll deal with foreign chars
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

# So we can run `add-apt-repository`
RUN apt-get -y --force-yes install software-properties-common

# https://askubuntu.com/a/756186
# Repository with PHP 5.6
RUN add-apt-repository -y ppa:ondrej/php

# We need to do this again argh
RUN apt-get update

RUN apt-get -y --force-yes install apache2
RUN apt-get -y --force-yes install \
    libapache2-mod-php5.6 \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-mysql \
    php5.6-xml \
    composer
RUN apt-get -y --force-yes install php5.6-xdebug

# https://github.com/docker-library/php/blob/78125d0d3c32a87a05f56c12ca45778e3d4bb7c9/5.6/stretch/apache/Dockerfile#L48
ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars

# https://github.com/docker-library/php/blob/78125d0d3c32a87a05f56c12ca45778e3d4bb7c9/5.6/stretch/apache/Dockerfile#L51
RUN set -ex \
	\
# generically convert lines like
#   export APACHE_RUN_USER=www-data
# into
#   : ${APACHE_RUN_USER:=www-data}
#   export APACHE_RUN_USER
# so that they can be overridden at runtime ("-e APACHE_RUN_USER=...")
	&& sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS" \
	\
# setup directories and permissions
	&& . "$APACHE_ENVVARS" \
	&& for dir in \
		"$APACHE_LOCK_DIR" \
		"$APACHE_RUN_DIR" \
		"$APACHE_LOG_DIR" \
		/var/www/html \
	; do \
		rm -rvf "$dir" \
		&& mkdir -p "$dir" \
		&& chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$dir"; \
	done

# https://github.com/docker-library/php/blob/78125d0d3c32a87a05f56c12ca45778e3d4bb7c9/5.6/stretch/apache/Dockerfile#L78
# logs should go to stdout / stderr
RUN set -ex \
	&& . "$APACHE_ENVVARS" \
	&& ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log"

# Configure xdebug (required so it works) 
ADD xdebug_settings.ini /etc/php/5.6/mods-available/xdebug_settings.ini

# Enable PHP's errors
ADD dev-env.ini /etc/php/5.6/apache2/conf.d/dev-env.ini

# We don't want xdeub on cli
RUN rm /etc/php/5.6/cli/conf.d/20-xdebug.ini

# Replace homepage with phpinfo()
RUN echo "<?php phpinfo();" > /var/www/html/index.php

# We may need these ports
EXPOSE 80 9000

VOLUME /var/www/html
VOLUME APACHE_LOG_DIR

WORKDIR /var/www/html

ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

# docker build -t ${PWD##*/} .
# docker container rm -f hostgator-php; \
## docker container create -p 8080:80 --name hostgator-php php-dev-env && \
## docker start hostgator-php