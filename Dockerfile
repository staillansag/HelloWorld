FROM staillansag/webmethods-microservicesruntime:10.15-dce-driver

EXPOSE 5555
EXPOSE 5543
EXPOSE 9999


# user to be used when running scripts
USER sagadmin

# files to be added to based image (includes configuration and package)

ADD --chown=sagadmin . /opt/softwareag/IntegrationServer/packages/HelloWorld
ADD --chown=sagadmin application.properties /opt/softwareag/IntegrationServer/application.properties
ADD --chown=sagadmin application.properties.test /opt/softwareag/IntegrationServer/application.properties.test
ADD --chown=sagadmin jms/jndi_DEFAULT_IS_JNDI_PROVIDER.properties /opt/softwareag/IntegrationServer/config/jndi/jndi_DEFAULT_IS_JNDI_PROVIDER.properties
ADD --chown=sagadmin jms/jms.cnf /opt/softwareag/IntegrationServer/config/jms.cnf

RUN chmod -R g=u /opt/softwareag/IntegrationServer/packages/HelloWorld
RUN chmod g=u /opt/softwareag/IntegrationServer/config/jms.cnf
RUN chmod g=u /opt/softwareag/IntegrationServer/config/jndi/jndi_DEFAULT_IS_JNDI_PROVIDER.properties