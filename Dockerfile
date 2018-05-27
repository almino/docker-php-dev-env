FROM ubuntu:14.04

RUN apt-get update
RUN apt-get -y --force-yes install apache2 php5 php5-xdebug

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
RUN tee /etc/php5/mods-available/xdebug_settings.ini <<EOF \ 
xdebug.default_enable = 1 \ 
xdebug.collect_params = 0 \ 
xdebug.collect_vars = 0 \ 
 \ 
xdebug.remote_connect_back = 1 \ 
xdebug.remote_enable = 1 \ 
xdebug.remote_port = 9000 \ 
EOF

# We don't want xdeub on cli
RUN rm /etc/php5/cli/conf.d/20-xdebug.ini

RUN echo "<?php phpinfo();" > /var/www/html/index.php

EXPOSE 80 9000

ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

# docker build -t ${PWD##*/} .
# docker container rm -f hostgator-php; \
## docker container create -p 8080:80 --name hostgator-php php-dev-env && \
## docker start hostgator-php