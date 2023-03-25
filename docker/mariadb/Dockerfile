FROM mariadb:10.9.5

ARG UID

RUN usermod -u ${UID} mysql; groupmod -g ${UID} mysql;

RUN chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
