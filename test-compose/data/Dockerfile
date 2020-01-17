FROM tier/grouper:latest

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"
 
COPY container_files/seed-data/ /seed-data/
COPY container_files/conf/ /opt/grouper/grouper.apiBinary/conf/

RUN yum install -y epel-release \
    && yum update -y \
    && yum install -y 389-ds-base 389-admin 389-adminutil mariadb-server mariadb \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN mysql_install_db \
    && chown -R mysql:mysql /var/lib/mysql/ \
    && sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/my.cnf \
    && sed -i 's/^\(log_error\s.*\)/# \1/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\ncharacter_set_server = utf8/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\ncollation_server = utf8_general_ci/' /etc/my.cnf \
    && sed -i 's/\[mysqld\]/\[mysqld\]\nport = 3306/' /etc/my.cnf \
    && cat  /etc/my.cnf \
    && echo "/usr/bin/mysqld_safe &" > /tmp/config \
    && echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config \
    && echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config \
    && echo "mysql -e 'CREATE DATABASE grouper CHARACTER SET utf8 COLLATE utf8_bin;'" >> /tmp/config \
    && bash /tmp/config \
    && rm -f /tmp/config \
    && mysql grouper < /seed-data/sisData.sql

RUN useradd ldapadmin \
    && rm -fr /var/lock /usr/lib/systemd/system \
    # The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install. \
    && sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm \
    # Not doing SELinux \
    && sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/* \
    # Do not restart at the end \
    && sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/* \
    && setup-ds.pl --silent --file /seed-data/ds-setup.inf \
    && /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir \ 
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    ldapadd -H ldap:/// -f /seed-data/users.ldif -x -D "cn=Directory Manager" -w password

RUN (/usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir &) \
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    (mysqld_safe & ) \
    && while ! curl -s localhost:3306 > /dev/null; do echo waiting for mysqld to start; sleep 1; done; \
    bin/gsh -registry -check -runscript -noprompt \
    && bin/gsh /seed-data/bootstrap.gsh

EXPOSE 389 3306

CMD /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir && mysqld_safe
