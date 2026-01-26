FROM tomcat:9.0.115-jdk8-temurin-noble

# Define arguments for drivers and profiler
ARG YOURKIT_URL=https://webratio-public-resources.s3.eu-central-1.amazonaws.com/YourKit
ARG YOURKIT_VERSION=2019.1
ARG YOURKIT_BUILD=b133
ARG MYSQL_JDBC_DRIVER_URL=https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar
ARG POSTGRESQL_JDBC_DRIVER_URL=https://jdbc.postgresql.org/download/postgresql-42.7.9.jar
ARG JAVA_MAIL_VERSION=1.6.2

ENV UMASK="0022"

# 1. Install utilities & Clean webapps
RUN apt-get update -y && \
    apt-get install -y unzip wget tzdata locales && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/tomcat/webapps/* && \
    mkdir -p /usr/local/tomcat/webapps

# 2. Configure setenv.sh (Memory, YourKit, and Property Source)
# This allows server.xml to read environment variables like ${MAX_THREADS}
RUN echo 'JAVA_OPTS="${MORE_JAVA_OPTS} -Xmx${JAVA_HEAP_SIZE} -Xms${JAVA_HEAP_SIZE} -XX:MaxMetaspaceSize=${JAVA_METASPACE_SIZE} -XX:+IgnoreUnrecognizedVMOptions -XX:+UseCompressedOops -server ${DEBUG_OPTIONS} ${YOURKIT_OPTIONS} -Djava.security.egd=file:/dev/./urandom"' > /usr/local/tomcat/bin/setenv.sh && \
    echo 'CATALINA_OPTS="${MORE_CATALINA_OPTS} -Dorg.apache.jasper.runtime.JspFactoryImpl.USE_POOL=false -Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=org.apache.tomcat.util.digester.EnvironmentPropertySource"' >> /usr/local/tomcat/bin/setenv.sh && \
    chmod +x /usr/local/tomcat/bin/setenv.sh

# 3. Edit server.xml (Connector, Executor, and Error Valve)
    # Add sharedThreadPool and Custom Connector on 8080
RUN PATTERN='<Service name="Catalina">' && \
    REPLACE_EXEC='<Executor name="sharedThreadPool" namePrefix="catalina-exec-" maxThreads="${TOMCAT_MAX_THREADS}" minSpareThreads="${TOMCAT_MIN_SPARE_THREADS}"/>' && \
    REPLACE_CONN='<Connector URIEncoding="UTF-8" executor="sharedThreadPool" port="8080" protocol="HTTP/1.1" connectionTimeout="20000" asyncTimeout="${TOMCAT_ASYNC_TIMEOUT}" secure="true" scheme="https" redirectPort="8443" proxyPort="443" server="-" compression="${TOMCAT_CONNECTOR_COMPRESSION}" maxHttpHeaderSize="65536" maxParameterCount="-1">' && \
    REPLACE_H2='<UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol"/></Connector>' && \
    sed -i "s|$PATTERN|\0\n    $REPLACE_EXEC\n    $REPLACE_CONN\n    $REPLACE_H2|g" /usr/local/tomcat/conf/server.xml && \
    # Disable error page details \
    sed -i '/<\/Host>/i \  <Valve className="org.apache.catalina.valves.ErrorReportValve" showReport="false" showServerInfo="false" />' /usr/local/tomcat/conf/server.xml

# 4. JSP Optimizations in web.xml
RUN sed -i '/<servlet-class>org.apache.jasper.servlet.JspServlet<\/servlet-class>/a \
    <init-param><param-name>enablePooling</param-name><param-value>false</param-value></init-param>\n\
    <init-param><param-name>development</param-name><param-value>false</param-value></init-param>\n\
    <init-param><param-name>compilerSourceVM</param-name><param-value>1.7</param-value></init-param>\n\
    <init-param><param-name>compilerTargetVM</param-name><param-value>1.7</param-value></init-param>' /usr/local/tomcat/conf/web.xml

# 5. External Resources (Drivers, YourKit)
RUN # YourKit \
    wget ${YOURKIT_URL}/${YOURKIT_VERSION}/YourKit-JavaProfiler-${YOURKIT_VERSION}-${YOURKIT_BUILD}.zip && \
    unzip YourKit-JavaProfiler-${YOURKIT_VERSION}-${YOURKIT_BUILD}.zip -d /opt/yjp && \
    rm -f YourKit-JavaProfiler-${YOURKIT_VERSION}-${YOURKIT_BUILD}.zip && \
    # JDBC Drivers & Mail \
    wget -P /usr/local/tomcat/lib "${MYSQL_JDBC_DRIVER_URL}" && \
    wget -P /usr/local/tomcat/lib "${POSTGRESQL_JDBC_DRIVER_URL}" --no-check-certificate && \
    wget -P /usr/local/tomcat/lib https://repo1.maven.org/maven2/com/sun/mail/javax.mail/${JAVA_MAIL_VERSION}/javax.mail-${JAVA_MAIL_VERSION}.jar

# 6. Scripts and Certificates
COPY import_self_signed_certs.sh set_timezone.sh /usr/local/tomcat/bin/
COPY sectigo-aaa-certificate-services-root.cer /usr/local/tomcat/sectigo-aaa-certificate-services-root.cer
COPY javadump.sh /javadump.sh

RUN chmod +x /usr/local/tomcat/bin/*.sh /javadump.sh && \
    keytool -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -importcert \
    -alias sectigo-aaa-certificate-services-root -file /usr/local/tomcat/sectigo-aaa-certificate-services-root.cer

ENV LANG=en_US.UTF-8

# Application Deployment: Copy your WAR here as ROOT.war
# COPY target/your-app.war /usr/local/tomcat/webapps/ROOT.war

CMD ["sh", "-c", "umask ${UMASK:-0022} && /usr/local/tomcat/bin/set_timezone.sh && /usr/local/tomcat/bin/import_self_signed_certs.sh && exec /usr/local/tomcat/bin/catalina.sh run"]