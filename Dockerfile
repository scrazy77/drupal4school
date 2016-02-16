FROM drupal:7
MAINTAINER fosstp drupal team

RUN apt-get update \
    && apt-get -y --no-install-recommends install ksh unzip gcc make git freetds-dev php-pear libldap2-dev mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap pcntl zip

#https://www-304.ibm.com/support/docview.wss?rs=71&uid=swg27007053
RUN mkdir /opt/ibm \
    && cd /opt/ibm \
    && curl -fSL "https://www.dropbox.com/s/naq3p1hx852huxl/v10.5fp6_linuxx64_dsdriver.tar.gz?dl=0" -o dsdriver.tar.gz \
    && tar -xzf dsdriver.tar.gz \
    && rm -rf dsdriver.tar.gz \
    && chmod +x /opt/ibm/dsdriver/installDSDriver \
    && /opt/ibm/dsdriver/installDSDriver \
    && echo "/opt/ibm/dsdriver" | pecl install ibm_db2
RUN { \
	echo 'extension=ibm_db2.so'; \
	echo 'ibm_db2.instance_name=db2inst1'; \
    } > /usr/local/etc/php/conf.d/30-ibm_db2.ini \
    && chmod a+w /usr/local/etc/php/ /usr/local/etc/php/conf.d \
    && chmod a+r -R /usr/local/lib/php/extensions \
    && echo 'TLS_REQCERT	never' >> /etc/ldap/ldap.conf

#Now, install composer, drush then install google api client library.
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && ln -s /usr/local/bin/composer /usr/bin/composer \
    && git clone https://github.com/drush-ops/drush.git /usr/local/src/drush \
    && cd /usr/local/src/drush \
    && git checkout 7.x \
    && ln -s /usr/local/src/drush/drush /usr/bin/drush \
    && composer install \
    && cd /var/www/html \
    && composer require google/apiclient:1.*

ADD modules /var/www/html/sites/all/modules
ADD themes /var/www/html/sites/all/themes
ADD translations /var/www/html/sites/default/files/translations
RUN chown -R www-data:www-data /var/www/html

ADD run-httpd.sh /usr/sbin/run-httpd.sh
RUN chmod +x /usr/sbin/run-httpd.sh

EXPOSE 80 443 9005
CMD ["/usr/sbin/run-httpd.sh"]
