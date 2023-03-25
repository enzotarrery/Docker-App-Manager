FROM httpd:2.4

LABEL author="Enzo Tarrery <tarrery.enzo@gmail.com>"

ARG UID

# We load the virtualhosts
COPY ./vhosts /usr/local/apache2/conf/sites

# We include the virtualhosts conf files into apache main conf file
RUN echo "Include conf/sites/*.conf" >> /usr/local/apache2/conf/httpd.conf

# We load the modules needed for apache to interpret PHP with FastCGI 
# and rename the user daemon to www-data (which will be us)
RUN sed -i '/LoadModule proxy_module/s/^#//g' /usr/local/apache2/conf/httpd.conf \
    && sed -i '/LoadModule proxy_fcgi_module/s/^#//g' /usr/local/apache2/conf/httpd.conf \
    && sed -i '/LoadModule rewrite_module modules/s/^#//g' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's/User daemon/User www-data/g' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's/Group daemon/Group www-data/g' /usr/local/apache2/conf/httpd.conf

# We uncomment the line concerning the usage of a certificate (SSL)
RUN sed -i \
    -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
    -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
    conf/httpd.conf

# We use a certificate to protect our server
COPY ./server.crt /usr/local/apache2/conf/server.crt
COPY ./server.key /usr/local/apache2/conf/server.key

# We change the UID of the user www-data so that it has ours 
# (we become www-data and have all rights)
RUN usermod -u ${UID} www-data

# Default port apache listens to
EXPOSE 80
# Default port apache listens to in case of a TLS configuration
EXPOSE 443