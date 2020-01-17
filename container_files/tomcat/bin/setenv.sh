CLASSPATH=/opt/tomcat/bin/*
JAVA_OPTS="-Dlog4j.configurationFile=/opt/tomcat/conf/log4j2.xml -DENV=$ENV -DUSERTOKEN=$USERTOKEN"
LOGGING_MANAGER=-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager