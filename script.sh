#!/bin/bash

TOMCAT_URL="https://www-eu.apache.org/dist/tomcat/tomcat-9/v8.5.43/bin/apache-tomcat-8.5.43.tar.gz"

function check_java_home {
    if [ -z ${JAVA_HOME} ]
    then
        echo 'Could not find JAVA_HOME. Please install Java and set JAVA_HOME'
	exit
    else 
	echo 'JAVA_HOME found: '$JAVA_HOME
        if [ ! -e ${JAVA_HOME} ]
        then
	    echo 'Invalid JAVA_HOME. Make sure your JAVA_HOME path exists'
	    exit
        fi
    fi
}

echo 'Installing tomcat server...'
echo 'Checking for JAVA_HOME...'
check_java_home

echo 'Downloading tomcat-8.5...'
if [ ! -f /etc/apache-tomcat-8*tar.gz ]
then
    curl -O $TOMCAT_URL
fi
echo 'Finished downloading...'

echo 'Creating install directories...'
sudo mkdir -p '/opt/tomcat/8_5'

if [ -d "/opt/tomcat/8_5" ]
then
    echo 'Extracting binaries to install directory...'
    sudo tar xzf apache-tomcat-8*tar.gz -C "/opt/tomcat/8_5" --strip-components=1
    echo 'Creating tomcat user group...'
    sudo groupadd tomcat
    sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
    
    echo 'Setting file permissions...'
    cd "/opt/tomcat/8_5"
    sudo chgrp -R tomcat "/opt/tomcat/8_5"
    sudo chmod -R g+r conf
    sudo chmod -R g+x conf

    # This should be commented out on a production server
    sudo chmod -R g+w conf

    sudo chown -R tomcat webapps/ work/ temp/ logs/
    
    TOMCAT_DIR="tomcat.init"

    echo 'Setting up TOMCAT_DIR...'
    sudo touch TOMCAT_DIR
    sudo chmod 777 TOMCAT_DIR 
    echo "[Unit]" > TOMCAT_DIR
    echo "Description=Apache Tomcat Web Application Container" >> TOMCAT_DIR
    echo "After=network.target" >> TOMCAT_DIR

    echo "[Service]" >> TOMCAT_DIR
    echo "Type=forking" >> TOMCAT_DIR

    echo "Environment=JAVA_HOME=$JAVA_HOME" >> TOMCAT_DIR
    echo "Environment=CATALINA_PID=/opt/tomcat/8_5/temp/tomcat.pid" >> TOMCAT_DIR
    echo "Environment=CATALINA_HOME=/opt/tomcat/8_5" >> TOMCAT_DIR
    echo "Environment=CATALINA_BASE=/opt/tomcat/8_5" >> TOMCAT_DIR
    echo "Environment=CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC" >> TOMCAT_DIR
    echo "Environment=JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom" >> TOMCAT_DIR

    echo "ExecStart=/opt/tomcat/8_5/bin/startup.sh" >> TOMCAT_DIR
    echo "ExecStop=/opt/tomcat/8_5/bin/shutdown.sh" >> TOMCAT_DIR

    echo "User=tomcat" >> TOMCAT_DIR
    echo "Group=tomcat" >> TOMCAT_DIR
    echo "UMask=0007" >> TOMCAT_DIR
    echo "RestartSec=10" >> TOMCAT_DIR
    echo "Restart=always" >> TOMCAT_DIR

    echo "[Install]" >> TOMCAT_DIR
    echo "WantedBy=multi-user.target" >> TOMCAT_DIR

    sudo mv TOMCAT_DIR /etc/systemd/system/TOMCAT_DIR
    sudo chmod 755 /etc/systemd/system/TOMCAT_DIR
    sudo systemctl daemon-reload
    
    echo 'Starting tomcat server....'
    sudo systemctl start tomcat
    exit
else
    echo 'Could not locate installation direcotry..exiting..'
    exit
fi