FROM webratio/tomcat:9.0.115-jdk8-temurin-noble

# 1. Download the official Tomcat Sample WAR
# This sample app contains basic JSPs and Servlets to verify your config
RUN wget -O /usr/local/tomcat/webapps/ROOT.war \
    https://tomcat.apache.org/tomcat-9.0-doc/appdev/sample/sample.war

# The CMD is already defined in your base image, so no need to repeat it!