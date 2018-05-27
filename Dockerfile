FROM ubuntu:14.04

# We want to install stuff
RUN apt-get update
# Install stuff
RUN apt-get -y --force-yes install apache2 php5 php5-xdebug multitail

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

# Configure php to show errors
RUN tee /etc/php5/apache2/conf.d/dev-env.ini <<EOF \
error_reporting = E_ALL \
display_errors = On \
display_startup_errors = On \
track_errors = On \
EOF

# We don't want to debug cli
RUN rm /etc/php5/cli/conf.d/20-xdebug.ini

# Remove apache2's default landing page
RUN rm /var/www/html/index.html
# Show phpinfo() page instead
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

# Ports usefull for PHP development
EXPOSE 80 9000

# RUN service apache2 start
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

# CMD [ "multitail", "/var/log/apache2/access.log", "-I", "/var/log/apache2/error.log" ]