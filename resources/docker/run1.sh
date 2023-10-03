MICROSERVICE_HOME=/Users/stephanetailland/dev/HelloWorld
CONTAINER_NAME=msrdce
HOST_PORT=15555

docker run --name $CONTAINER_NAME \
	--network sag \
	-d -p $HOST_PORT:5555 \
	-v $MICROSERVICE_HOME/resources/docker/license/msr-license.xml:/opt/softwareag/IntegrationServer/config/licenseKey.xml:ro \
	-v $MICROSERVICE_HOME/application.properties:/opt/softwareag/IntegrationServer/application.properties \
	-v $MICROSERVICE_HOME:/opt/softwareag/IntegrationServer/packages/HelloWorld \
	-v $MICROSERVICE_HOME/jms/jms.cnf:/opt/softwareag/IntegrationServer/config/jms.cnf \
	-v $MICROSERVICE_HOME/resources/docker/keystores/msr.truststore.jks:/opt/softwareag/common/conf/keystores/msr.truststore.jks:ro \
	--env-file=.env \
	staillansag/msr-dce-dev:latest
