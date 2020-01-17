FROM tier/grouper:latest

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

COPY container_files/web.xml /opt/grouper/grouper.scim/WEB-INF/
COPY container_files/tomcat-users.xml /opt/tomee/conf/

CMD ["scim"]
