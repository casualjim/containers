FROM java:alpine

VOLUME /opt/dynamodb
WORKDIR /opt/dynamodb

RUN set -e &&\
  apk add --no-cache curl ca-certificates &&\
  mkdir -p /usr/share/dynamodb &&\
  curl -sL http://dynamodb-local.s3-website-us-west-2.amazonaws.com/dynamodb_local_latest.tar.gz | tar -C /usr/share/dynamodb -xz &&\
  apk del --no-cache curl ca-certificates

EXPOSE 8000

ENTRYPOINT ["java", "-Djava.library.path=/usr/share/dynamodb/DynamoDBLocal_lib", "-jar", "/usr/share/dynamodb/DynamoDBLocal.jar"]
CMD ["-sharedDb", "-optimizeDbBeforeStartup", "-dbPath", "/opt/dynamodb"]
