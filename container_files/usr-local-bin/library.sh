#!/bin/sh

setupPipe() {
    if [ -e $1 ]; then
        rm $1
    fi
    mkfifo -m 666 $1
}

setupLoggingPipe() {
    # Make a "console" logging pipe that anyone can write too regardless of who owns the process.
    setupPipe /tmp/logpipe
    cat <> /tmp/logpipe &
}

# Make loggers pipes for the supervisord connected apps' console, so that we can prepend the streams.
setupGrouperLogPipe() {
    setupPipe /tmp/loggrouper
    (cat <> /tmp/loggrouper | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "grouper;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' &>/tmp/logpipe) &
}

setupHttpdLogPipe() {
    setupPipe /tmp/loghttpd
    (cat <> /tmp/loghttpd  | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "httpd;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' &>/tmp/logpipe) &
}

setupShibdLogPipe() {
    setupPipe /tmp/logshibd
    (cat <> /tmp/logshibd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shibd;console;%s;%s;%s", ENV, UT, $0; fflush()}' &>/tmp/logpipe) &
}

setupTomcatLogPipe() {
    setupPipe /tmp/logtomcat
    (cat <> /tmp/logtomcat | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "tomcat;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' &>/tmp/logpipe) &
}

setupSupervisordLogPipe() {
    setupPipe /tmp/logsuperd
    (cat <> /tmp/logsuperd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "supervisord;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' &>/tmp/logpipe) &
}

linkGrouperSecrets() {
    for filepath in /run/secrets/*; do
        local label_file=`basename $filepath`
        local file=$(echo $label_file| cut -d'_' -f 2)

        if [[ $label_file == grouper_* ]]; then
            ln -sf /run/secrets/$label_file $1/$file
        elif [[ $label_file == shib_* ]]; then
            ln -sf /run/secrets/$label_file /etc/shibboleth/$file
        elif [[ $label_file == httpd_* ]]; then
            ln -sf /run/secrets/$label_file /etc/httpd/conf.d/$file
        elif [ "$label_file" == "host-key.pem" ]; then
            ln -sf /run/secrets/host-key.pem /etc/pki/tls/private/host-key.pem
        fi
    done
}

prepDaemon() {
    setupLoggingPipe
    setupGrouperLogPipe
}

prepDaemonConf() {
    local dest=/opt/grouper/grouper.apiBinary
    linkGrouperSecrets $dest/conf

    if [ -d "/opt/grouper/conf" ]; then
        cp -r /opt/grouper/conf/* $dest/conf/
    fi
    if [ -d "/opt/grouper/lib" ]; then
        cp -r /opt/grouper/lib/* $dest/lib/custom/
    fi      
}

prepSCIM() {
    setupLoggingPipe
    setupGrouperLogPipe
    setupHttpdLogPipe
    setupTomcatLogPipe

    
    cp /opt/tier-support/grouper-ws-scim.xml /opt/tomee/conf/Catalina/localhost/
}

prepSCIMConf() {
    local dest=/opt/grouper/grouper.scim/WEB-INF
    linkGrouperSecrets $dest/classes

    if [ -d "/opt/grouper/conf" ]; then
        cp -r /opt/grouper/conf/* $dest/classes/
    fi
    if [ -d "/opt/grouper/lib" ]; then
        cp -r /opt/grouper/lib/* $dest/lib/
    fi    
}

prepUI() {
    setupLoggingPipe
    setupGrouperLogPipe
    setupHttpdLogPipe
    setupShibdLogPipe
    setupTomcatLogPipe
    setupSupervisordLogPipe

    cp /opt/tier-support/grouper.xml /opt/tomcat/conf/Catalina/localhost/
}

prepUIConf() {
    local dest=/opt/grouper/grouper.ui/WEB-INF
    linkGrouperSecrets $dest/classes

    if [ -d "/opt/grouper/conf" ]; then
        cp -r /opt/grouper/conf/* $dest/classes/
    fi
    if [ -d "/opt/grouper/lib" ]; then
        cp -r /opt/grouper/lib/* $dest/lib/
    fi
}

prepWS() {
    setupLoggingPipe
    setupGrouperLogPipe
    setupHttpdLogPipe
    setupTomcatLogPipe
    setupSupervisordLogPipe

    cp /opt/tier-support/grouper-ws.xml /opt/tomcat/conf/Catalina/localhost/
}

prepWSConf() {
    local dest=/opt/grouper/grouper.ws/WEB-INF
    linkGrouperSecrets $dest/classes
    
    if [ -d "/opt/grouper/conf" ]; then
        cp -r /opt/grouper/conf/* $dest/classes/
    fi
    if [ -d "/opt/grouper/lib" ]; then
        cp -r /opt/grouper/lib/* $dest/lib/
    fi
}


prepConf() {
    prepDaemonConf
    prepSCIMConf
    prepUIConf
    prepWSConf
}