FROM php:5.6.40-apache

ENV EBOT_HOME="/ebot" \
    TIMEZONE="Europe/Copenhagen"

RUN mkdir -p ${EBOT_HOME}/demos ${EBOT_HOME}/logs ${EBOT_HOME}/ssl && a2enmod rewrite ssl && \
    docker-php-ext-install pdo_mysql && \
    echo 'date.timezone = "${TIMEZONE}"' >> /usr/local/etc/php/conf.d/php.ini && \
    apt-get update && apt-get -y install zip netcat cron socat apt-transport-https ca-certificates gnupg-agent software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get -y docker-ce docker-ce-cli containerd.io && \
    apt-get clean && \
    rm -rf /var/www/html/* && \
    curl -L https://github.com/enghausen/eBot-CSGO-Web/archive/master.zip >> /tmp/master.zip && \
    unzip -d /var/www/html /tmp/master.zip && \
    rm -rf /tmp/* && \
    mv /var/www/html/eBot-CSGO-Web-master/* /var/www/html/ &&\
    rm -rf /var/www/html/eBot-CSGO-Web-master /var/www/html/web/installation && \
    cp /var/www/html/config/app_user.yml.default /var/www/html/config/app_user.yml && \    
    chown www-data:www-data -R /var/www ${EBOT_HOME} && \
    curl https://raw.githubusercontent.com/certbot/certbot/master/certbot-apache/certbot_apache/_internal/tls_configs/current-options-ssl-apache.conf \ 
    -o /etc/apache2/options-ssl-apache.conf && \
    curl https://get.acme.sh | sh

RUN sed -i "s|#RewriteBase.*|RewriteBase /|" /var/www/html/web/.htaccess

COPY 000-default.conf default-ssl.conf /etc/apache2/sites-available/

RUN  a2ensite default-ssl.conf

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod +x /sbin/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/sbin/entrypoint.sh"]
