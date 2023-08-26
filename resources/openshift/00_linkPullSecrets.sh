# oc create secret docker-registry sagregcred \
#     --docker-server=sagcr.azurecr.io \
#     --docker-username=<sagcr.azurecr.io username> \
#     --docker-password=<sagcr.azurecr.io secret> \
#     --docker-email=<sagcr.azurecr.io email>

oc secrets link default sagregcred --for=pull
