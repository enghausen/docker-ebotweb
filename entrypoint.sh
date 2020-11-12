#!/bin/bash

# Domain for Apache/SSL and eBotWeb settings (used for the "ebot_ip:" in app_user.yml)
DOMAIN="${DOMAIN:-ebot.doamin.com}"

# MYSQL settings
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-ebotv3}"
MYSQL_PASS="${MYSQL_PASS:-ebotv3}"
MYSQL_DB="${MYSQL_DB:-ebotv3}"

# eBotWeb settings (settings in app_user.yml)
EBOT_WEB_HOME='/var/www/html'
EBOT_PROTO="${EBOT_PROTO:-https://}"
EBOT_PORT="${EBOT_PORT:-12360}"
EBOT_ADMIN_USER="${EBOT_ADMIN_USER:-admin}"
EBOT_ADMIN_PASS="${EBOT_ADMIN_PASS:-password}"
EBOT_ADMIN_MAIL="${EBOT_ADMIN_MAIL:-admin@ebot}"
DEMO_DOWNLOAD="${DEMO_DOWNLOAD:-true}"
DEMO_FOLDER="${DEMO_FOLDER:-/ebot/demos}"
LOG_FOLDER="${LOG_FOLDER:-/ebot/logs}"
DEFAULT_MAX_ROUND="${DEFAULT_MAX_ROUND:-15}"
DEFAULT_RULES="${DEFAULT_RULES:-ebot_config}"
DEFAULT_OVERTIME_MAX_ROUND="${DEFAULT_OVERTIME_MAX_ROUND:-3}"
DEFAULT_OVERTIME_STARTMONEY="${DEFAULT_OVERTIME_MAX_ROUND:-10000}"
MODE="${MODE:-net}"
REFRESH_TIME="${REFRESH_TIME:-30}"

# SSL settings
SSL_CERTIFICATE_PATH="${SSL_CERTIFICATE_PATH:-/ebot/ssl/fullchain.cer}"
SSL_KEY_PATH="${SSL_KEY_PATH:-/ebot/ssl/$DOMAIN.key}"

# Toonament settings
TOORNAMENT_ID="${TOORNAMENT_ID:-}"
TOORNAMENT_SECRET="${TOORNAMENT_SECRET:-}"
TOORNAMENT_API_KEY="${TOORNAMENT_API_KEY:-}"
TOORNAMENT_PLUGIN_KEY="${TOORNAMENT_PLUGIN_KEY:-}"

# PHP settings
TIMEZONE="${TIMEZONE:-Europe/Copenhagen}"

# Custom maps in app.yml
MAPS="${MAPS:-de_dust2, de_nuke, de_inferno, de_train, de_mirage, de_vertigo, de_cache, de_overpass, de_cbble,}"

# For usage with docker-compose
while ! nc -z $MYSQL_HOST $MYSQL_PORT; do sleep 3; done

if [ ! -f .installed ]
then
    php symfony configure:database "mysql:host=${MYSQL_HOST};dbname=${MYSQL_DB}" $MYSQL_USER $MYSQL_PASS
    php symfony doctrine:insert-sql
    php symfony guard:create-user --is-super-admin $EBOT_ADMIN_MAIL $EBOT_ADMIN_USER $EBOT_ADMIN_PASS

    # Manage eBotWeb configs (app_user.yml and app.yml)
    sed -i "s|log_match:.*|log_match: ${LOG_FOLDER}/log_match|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|log_match_admin:.*|log_match_admin: ${LOG_FOLDER}/log_match_admin|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|demo_path:.*|demo_path: ${DEMO_FOLDER}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|default_max_round:.*|default_max_round: ${DEFAULT_MAX_ROUND}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|default_rules:.*|default_rules: ${DEFAULT_RULES}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|default_overtime_max_round:.*|default_overtime_max_round: ${DEFAULT_OVERTIME_MAX_ROUND}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|default_overtime_startmoney:.*|default_overtime_startmoney: ${DEFAULT_OVERTIME_STARTMONEY}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|demo_download:.*|demo_download: ${DEMO_DOWNLOAD}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|ebot_proto:.*|ebot_proto: ${EBOT_PROTO}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|ebot_ip:.*|ebot_ip: ${DOMAIN}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|ebot_port:.*|ebot_port: ${EBOT_PORT}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|mode:.*|mode: ${MODE}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|refresh_time:.*|refresh_time: ${REFRESH_TIME}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|toornament_id:.*|toornament_id: ${TOORNAMENT_ID}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|toornament_secret:.*|toornament_secret: ${TOORNAMENT_SECRET}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|toornament_api_key:.*|toornament_api_key: ${TOORNAMENT_API_KEY}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|toornament_plugin_key:.*|toornament_plugin_key: ${TOORNAMENT_PLUGIN_KEY}|" $EBOT_WEB_HOME/config/app_user.yml
    sed -i "s|maps:.*|maps: [ ${MAPS} ]|" $EBOT_WEB_HOME/config/app.yml
    
    # Apache config
    sed -i "s|ServerName.*|ServerName $DOMAIN|" /etc/apache2/sites-available/000-default.conf
    sed -i "s|{SERVER_NAME} =.*|{SERVER_NAME} =$DOMAIN|" /etc/apache2/sites-available/000-default.conf
    sed -i "s|ServerName.*|ServerName $DOMAIN|" /etc/apache2/sites-available/default-ssl.conf
    sed -i "s|SSLCertificateFile.*|SSLCertificateFile $SSL_CERTIFICATE_PATH|" /etc/apache2/sites-available/default-ssl.conf
    sed -i "s|SSLCertificateKeyFile.*|SSLCertificateKeyFile $SSL_KEY_PATH|" /etc/apache2/sites-available/default-ssl.conf
    
    # PHP config
    sed -i "s|date.timezone =.*|date.timezone = \"$TIMEZONE\"|" /usr/local/etc/php/conf.d/php.ini
    
    touch .installed
fi

php symfony cc

apache2-foreground
