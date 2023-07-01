docker run --name msr-hello-world \
	--network sag\
	-d -p 5555:5555 \
	-v /home/DAEDMZ/stai/licence/msr.xml:/opt/softwareag/IntegrationServer/config/licenseKey.xml:ro \
	--env-file=.env \
	staillansag/msr-dce:0.0.1
