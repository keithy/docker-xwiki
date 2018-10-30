# don't run as root
# http://blog.dscpl.com.au/2015/12/random-user-ids-when-running-docker.html
adduser --disabled-password --uid 888 --gid 0 --gecos "Xwiki" xwiki
 
# Install LibreOffice + other tools
# Note that procps is required to get ps which is used by JODConverter to start LibreOffice
 
apt-get update
apt-get --no-install-recommends -y install \
     curl \
     libreoffice \
     unzip \
     procps 

# prepare directories    
rm -rf /usr/local/tomcat/webapps/*
mkdir -p /usr/local/tomcat/temp
mkdir -p /usr/local/xwiki/data

# Use a local war if present (saves repeated downloading while debugging)
if [ ! -f /build/xwiki-${XWIKI_VERSION}.war ]; then
	curl -fSL "${XWIKI_URL_PREFIX}/${XWIKI_VERSION}/xwiki-platform-distribution-war-${XWIKI_VERSION}.war" \
	     -o   "/build/xwiki-${XWIKI_VERSION}.war"
fi

echo "$XWIKI_DOWNLOAD_SHA256 /build/xwiki-${XWIKI_VERSION}.war" | sha256sum -c -
unzip -d /usr/local/tomcat/webapps/ROOT /build/xwiki-${XWIKI_VERSION}.war

# Copy the JDBC driver into the XWiki webapp
case $DB in
 mysql)
   apt-get install libmysql-java
   cp /usr/share/java/mysql-connector-java-*.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/
 ;;
 postgres)
   apt-get install libpostgresql-jdbc-java
   cp /usr/share/java/postgresql-jdbc4.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/
  ;;
 oracle)
   echo "oracle placeholder"
  ;;
esac

# Set a specific distribution id in XWiki for this docker packaging.
sed -i 's/<id>org.xwiki.platform:xwiki-platform-distribution-war</<id>org.xwiki.platform:xwiki-platform-distribution-docker</' \
  /usr/local/tomcat/webapps/ROOT/META-INF/extension.xed 

# To Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
# COPY tomcat/setenv.sh /usr/local/tomcat/bin/
# Add scripts required to make changes to XWiki configuration files at execution time
# Note: we don't run CHMOD since 1) it's not required since the executabe bit is already set in git and 2) running
# CHMOD after a COPY will sometimes fail, depending on different host-specific factors (especially on AUFS).
# COPY xwiki/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Setup the XWiki Hibernate configuration
cp /build/$DB/hibernate.cfg.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# tidy up
rm -rf /var/lib/apt/lists/* 
rm -rf /build 

#ensure xwiki ownership
chmod -R ug+w /usr/local/tomcat/webapps/ROOT
chmod -R ug+w /usr/local/tomcat/temp
chmod -R ug+w /usr/local/xwiki/data
chown -R xwiki:root /usr/local/tomcat/webapps/ROOT
chown -R xwiki:root /usr/local/tomcat/temp
chown -R xwiki:root /usr/local/xwiki/data
