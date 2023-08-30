FROM staillansag/msr-dce-dev:latest

EXPOSE 5555
EXPOSE 5543
EXPOSE 9999

USER sagadmin

ADD --chown=sagadmin . /opt/softwareag/IntegrationServer/packages/HelloWorld
ADD --chown=sagadmin application.properties /opt/softwareag/IntegrationServer/application.properties
ADD --chown=sagadmin application.properties.test /opt/softwareag/IntegrationServer/application.properties.test

RUN chmod -R g=u /opt/softwareag/IntegrationServer/packages/HelloWorld
