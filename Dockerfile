FROM ubuntu:14.04

RUN apt-get update
RUN apt-get -y --force-yes install apache2 php5 php5-xdebug multitail

ADD xdebug_settings.ini /etc/php5/mods-available/
RUN rm /etc/php5/cli/conf.d/20-xdebug.ini

RUN rm /var/www/html/index.html
RUN echo "<?php phpinfo();" > /var/www/html/index.php

EXPOSE 80 9000

# RUN service apache2 start

ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

# CMD [ "multitail", "/var/log/apache2/access.log", "-I", "/var/log/apache2/error.log" ]