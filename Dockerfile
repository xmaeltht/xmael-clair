FROM centos:centos7 as installing

RUN yum update -y \
    && yum install -y wget tar unzip dos2unix \
    && yum clean all
    
ARG GROUPER_CONTAINER_VERSION

ENV GROUPER_VERSION=2.4.0 \
     JAVA_HOME=/usr/lib/jvm/zulu-8/ \
     GROUPER_CONTAINER_VERSION=$GROUPER_CONTAINER_VERSION

# use Zulu package
RUN rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems \
       && curl -o /etc/yum.repos.d/zulu.repo http://repos.azulsystems.com/rhel/zulu.repo \
       && yum -y install zulu-8 

#RUN java_version=8.0.172; \
#    zulu_version=8.30.0.1; \
#    echo 'Downloading the OpenJDK Zulu...' \
#    && wget -q http://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
#    && echo "0a101a592a177c1c7bc63738d7bc2930  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
#    && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
#    && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64 $JAVA_HOME

#RUN java_version=8u151; \
#    java_bnumber=12; \
#    java_semver=1.8.0_151; \
#    java_hash=123b1d755416aa7579abc03f01ab946e612e141b6f7564130f2ada00ed913f1d; \
#    echo 'Downloading the Oracle Java...' \ 
#    && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#    http://download.oracle.com/otn-pub/java/jdk/$java_version-b$java_bnumber/e758a0de34e24606bca991d704f6dcbf/server-jre-$java_version-linux-x64.tar.gz \
#    && echo "$java_hash  server-jre-$java_version-linux-x64.tar.gz" | sha256sum -c - \
#    && tar -zxvf server-jre-$java_version-linux-x64.tar.gz -C /opt \
#    && ln -s /opt/jdk$java_semver/ $JAVA_HOME

RUN echo 'Downloading Grouper Installer...' \
    && mkdir -p /opt/grouper/$GROUPER_VERSION \
    && wget -q -O /opt/grouper/$GROUPER_VERSION/grouperInstaller.jar http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouperInstaller.jar

COPY container_files/grouper.installer.properties /opt/grouper/$GROUPER_VERSION

RUN echo 'Installing Grouper'; \
    PATH=$PATH:$JAVA_HOME/bin; \
    cd /opt/grouper/$GROUPER_VERSION/ \
    && $JAVA_HOME/bin/java -cp :grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller



FROM centos:centos7 as cleanup

ENV GROUPER_VERSION=2.4.0 \
    TOMCAT_VERSION=8.5.12 \    
    TOMEE_VERSION=7.0.0

COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouperInstaller.jar /opt/grouper/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouper.apiBinary-$GROUPER_VERSION/ /opt/grouper/grouper.apiBinary/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouper.ui-$GROUPER_VERSION/dist/grouper/ /opt/grouper/grouper.ui/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouper.ws-$GROUPER_VERSION/grouper-ws/build/dist/grouper-ws/ /opt/grouper/grouper.ws/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouper.ws-$GROUPER_VERSION/grouper-ws-scim/targetBuiltin/grouper-ws-scim/ /opt/grouper/grouper.scim/
#COPY --from=installing /opt/grouper/$GROUPER_VERSION/grouper.clientBinary-$GROUPER_VERSION/ /opt/grouper/grouper.clientBinary/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/apache-tomcat-$TOMCAT_VERSION/ /opt/tomcat/
COPY --from=installing /opt/grouper/$GROUPER_VERSION/apache-tomee-webprofile-$TOMEE_VERSION/ /opt/tomee/
COPY --from=installing /etc/alternatives/java /etc/alternatives/java

ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.11.0/log4j-core-2.11.0.jar /opt/tomcat/bin
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.11.0/log4j-api-2.11.0.jar /opt/tomcat/bin
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-jul/2.11.0/log4j-jul-2.11.0.jar /opt/tomcat/bin

ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.11.0/log4j-core-2.11.0.jar /opt/tomee/bin
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.11.0/log4j-api-2.11.0.jar /opt/tomee/bin
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-jul/2.11.0/log4j-jul-2.11.0.jar /opt/tomee/bin

RUN cd /opt/grouper/grouper.apiBinary/; \
    rm -fr ddlScripts/ grouper.lck grouper.log grouper.script grouper.tmp/ gshAddGrouperSystemWsGroup.gsh logs/

RUN cd /opt/tomcat/; \
    chmod +r bin/log4j-*.jar; \
    rm -fr webapps/docs/ webapps/examples/ webapps/host-manager/ webapps/manager/ webapps/ROOT/ logs/* temp/* work/* conf/logging.properties

RUN cd /opt/tomee/; \
    chmod +r bin/log4j-*.jar; \
    rm -fr webapps/docs/ webapps/host-manager/ webapps/manager/ logs/* temp/* work/* conf/logging.properties

COPY container_files/api/* /opt/grouper/grouper.apiBinary/conf/
COPY container_files/ui/ /opt/grouper/grouper.ui/WEB-INF/
COPY container_files/ws/ /opt/grouper/grouper.ws/WEB-INF/
COPY container_files/tomcat/ /opt/tomcat/
COPY container_files/tomee/ /opt/tomee/


FROM tier/shibboleth_sp:3.0.4_03122019

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>" \
      Vendor="TIER" \
      ImageType="Grouper" \
      ImageName=$imagename \
      ImageOS=centos7
      
ARG GROUPER_CONTAINER_VERSION

ENV JAVA_HOME=/usr/lib/jvm/zulu-8/ \
    PATH=$PATH:$JAVA_HOME/bin \
    GROUPER_HOME=/opt/grouper/grouper.apiBinary \
    GROUPER_CONTAINER_VERSION=$GROUPER_CONTAINER_VERSION

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

RUN yum update -y \
    && yum install -y cron logrotate python-pip \
    && pip install --upgrade pip \
    && pip install supervisor \
    && yum clean -y all

COPY --from=installing $JAVA_HOME $JAVA_HOME
COPY --from=cleanup /opt/tomcat/ /opt/tomcat/
COPY --from=cleanup /opt/tomee/ /opt/tomee/
COPY --from=cleanup /opt/grouper/ /opt/grouper/

RUN groupadd -r tomcat \
    && useradd -r -m -s /sbin/nologin -g tomcat tomcat \
    && mkdir -p /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/work/ \
    && chown -R tomcat:tomcat /opt/tomcat/logs/ /opt/tomcat/temp/ /opt/tomcat/work/ \
    && chown -R tomcat:tomcat /opt/tomee/logs/ /opt/tomee/temp/ /opt/tomee/work/ \
    && ln -s $JAVA_HOME/bin/java /etc/alternatives/java

# does shib sp3 not generate these files?
# RUN rm /etc/shibboleth/sp-key.pem /etc/shibboleth/sp-cert.pem

COPY container_files/tier-support/ /opt/tier-support/
COPY container_files/usr-local-bin/ /usr/local/bin/
COPY container_files/httpd/* /etc/httpd/conf.d/
COPY container_files/shibboleth/* /etc/shibboleth/

RUN cp /dev/null /etc/httpd/conf.d/ssl.conf \
    && sed -i 's/LogFormat "/LogFormat "httpd;access_log;%{ENV}e;%{USERTOKEN}e;/g' /etc/httpd/conf/httpd.conf \
    && echo -e "\nErrorLogFormat \"httpd;error_log;%{ENV}e;%{USERTOKEN}e;[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i\"" >> /etc/httpd/conf/httpd.conf \
    && sed -i 's/CustomLog "logs\/access_log"/CustomLog "\/tmp\/logpipe"/g' /etc/httpd/conf/httpd.conf \
    && sed -i 's/ErrorLog "logs\/error_log"/ErrorLog "\/tmp\/logpipe"/g' /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv ENV" >> /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv USERTOKEN" >> /etc/httpd/conf/httpd.conf

WORKDIR /opt/grouper/grouper.apiBinary/

EXPOSE 80 443

HEALTHCHECK NONE

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["bin/gsh", "-loader"]
