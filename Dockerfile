FROM gurongyun/oralce-jre:8u221 as builder
ENV SONAR_SCANNER_PKG=sonar-scanner.zip \
    NODE_PKG=node-v8.14.1-linux-x64.tar.xz \
    MAVEN_PKG=apache-maven-3.5.2-bin.tar.gz 

COPY $SONAR_SCANNER_PKG /tmp/sonar-scanner.zip
COPY $NODE_PKG /tmp/node.tar.xz
COPY $MAVEN_PKG /tmp/maven.tar.gz

ENV SONAR_SCANNER_HOME=/usr/local/sonar-scanner \
    NODEJS_HOME=/usr/local/nodejs \
    MAVEN_HOME=/usr/local/apache-maven-3.5.2 

RUN set -eux \
    && yum install -y unzip \
    && rm -rf /var/cache/yum \
    && mkdir -p "$SONAR_SCANNER_HOME" \
    && mkdir -p "$NODEJS_HOME" \
    && mkdir -p "$MAVEN_HOME" \
    && unzip -q /tmp/sonar-scanner.zip -d /usr/local \
    && tar --extract --file /tmp/node.tar.xz --directory "$NODEJS_HOME" --strip-components 1 \ 
    && tar --extract --file /tmp/maven.tar.gz --directory "$MAVEN_HOME" --strip-components 1 \
    && rm -rf /tmp

FROM gurongyun/oralce-jre:8u221

ENV JENKINS_VERSION=4.0.1

ENV SONAR_SCANNER_HOME=/usr/local/sonar-scanner \
    NODEJS_HOME=/usr/local/nodejs \
    MAVEN_HOME=/usr/local/apache-maven-3.5.2 \
    DOCKER_HOME=/usr/local/docker

ENV NODE_PATH=$NODE_HOME/lib/node_modules

ENV PATH $SONAR_SCANNER_HOME/bin:$NODEJS_HOME/bin:$MAVEN_HOME/bin:$PATH
    
COPY --from=builder $SONAR_SCANNER_HOME $SONAR_SCANNER_HOME
COPY --from=builder $NODEJS_HOME $NODEJS_HOME
COPY --from=builder $MAVEN_HOME $MAVEN_HOME

RUN set -eux \
  && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_VERSION}/remoting-${JENKINS_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar \
  && mkdir -p /home/jenkins \
  && yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo \
  && yum install -y git \
                    docker-ce-cli-18.09.1 \
  && rm -rf /var/cache/yum \
  && rm -rf /etc/yum.repos.d/docker-ce.repo \
  && mvn --version \
  && git --version \
  && sonar-scanner --version \
  && node --version \
  && npm --version 

WORKDIR /home/jenkins

#ENV SONAR_SCANNER_OPTS=-Xmx512m
    

COPY jenkins-slave /usr/local/bin/
CMD ["jenkins-slave"]
