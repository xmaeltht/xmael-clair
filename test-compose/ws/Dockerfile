FROM tier/grouper:latest

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

COPY container_files/web.xml /opt/grouper/grouper.ws/WEB-INF/
COPY container_files/tomcat-users.xml /opt/tomcat/conf/
COPY container_files/server.xml /opt/tomcat/conf/

CMD ["ws"]
