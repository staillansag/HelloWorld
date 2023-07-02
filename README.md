# microservice webMethods Hello World

Ce repository montre l'utilisation du Microservice Runtime Software AG pour mettre en place un microservice Hello World.

## Architecture logique
![Architecture logique](resources/documentation/images/ArchitectureLogique.png)

## Gestion des dépendances

TODO

## Installation de l'environnement de développement

TODO

## Build de l'image Docker
![Structure de l'image Docker](resources/documentation/images/StructureImage.png)

### Image de base

L'image staillansag/webmethods-microservicesruntime:10.15-dce a été construite en utilisant les outils Software AG.
Voir le repository https://github.com/staillansag/sag-unattended-installations qui est un fork du repository officiel SAG.
J'ai créé un nouveau template pour intégrer les packages webMethods nécessaires: WmMonitor, WmJDBCAdapter, WmHDFSAdapter, WmCloudStreams.

TODO: automatiser le build de cette image de base par le biais d'un pipeline de CI/CD.

### Image de développement

L'image de base n'intègre pas de drivers JDBC. En fonction des SGBD sélectionnés pour la base de données webMethods et celle du microservice, on ajoute les drivers appropriés. 
Ici j'ai ajouté le driver DataDirect Connect pour la base de données webMethods (positionné dans common/lib/ext) et le driver Postgres pour la base de données du microservice (positionné dans WmJDBCAdapter/code/jars)

C'est cette image qui sert de base pour les développements dans le Service Designer.

### Image du microservice

Elle intègre le package HelloWorld du microservice et les éléments de configuration

## Déploiement Docker

TODO

## Déploiement Kubernetes

### Architecture de déploiement
![Architecture de déploiement](resources/documentation/images/ArchitectureDeploiement.png)

Le schéma mentionne des fichiers manifeste Kubernetes qui sont localisés dans le répertoire resources/kubernetes.

TODO: ajouter les fichiers suivants:
-   Secret TLS: 01_tls-Secret.yaml
-   Secret Registre de conteneur (uniquement utile si le registre est privé): 01_cr-Secret.yaml
-   Ingress: 99_Ingress.yaml
-   Horizontal Pod Autoscaler (HPA): 04_msr-hpa.yaml

### Déploiement test

Pour tester le déploiement dans Kubernetes, un mode spécifique a été mis en place, dans lequel le microservice n'a besoin d'aucune dépendance externe.  
Il suffit de faire pointer la variable SAG_IS_CONFIG_PROPERTIES vers le fichier properties /opt/softwareag/IntegrationServer/application.properties.test, dans le manifeste 02_msr-deployment.yaml  
Cette configuration désactive en particulier l'utilisation des bases de données externes.  Il n'est donc pas nécessaire de charger les fichiers de configuration 01_ms-ConfigMap.yaml et 01_ms-Secret.yaml  

Pour effectuer ce déploiement simplifié, il faut d'abord se positionner dans resources/kubernetes  

Créez le fichier 01_license-Secret.yaml en copiant 01_license-Secret.yaml.example  
Convertissez ensuite le contenu du fichier XML de license du Microservice Runtime en base64, par exemple en utilisant cette commande (où msr-license.xml est donc le nom du fichier XML de licence):
```
cat msr-license.xml | base64
```
Copiez la sortie de cette commande et coller là dans le fichier 01_license-Secret.yaml, à droite de la clé msr-license

Exécutez enfin les commandes suivantes pour charger les fichiers manifeste:
```
kubectl apply -f 00_dce-Namespace.yaml
kubectl apply -f 01_license-Secret.yaml
kubectl apply -f 02_msr-deployment.yaml
kubectl apply -f 03_msr-service.yaml
```

Normalement le déploiement devrait durer une à deux minutes.  
Pour vérifier le statut, nous pouvons utiliser plusieurs commandes.  

Statut du déploiment:
```
kubectl rollout status deployment msr-hello-world -n dce
```
Cette commande retourne ceci dans le cas où le déploiement est terminé:
```
deployment "msr-hello-world" successfully rolled out
```

Etat des pods:
```
kubectl get pods -n dce
```
Cette commande retourne ceci dans le cas où le déploiement est terminé (le suffixe du nom de pod sera ici différent):
```
NAME                                READY   STATUS    RESTARTS   AGE
msr-hello-world-5ff8986c66-bgp9n    1/1     Running   0          5h35m
```

Etat du service:
```
kubectl get svc -n dce
```
Cette commande retourne ceci dans le cas où le service est démarré (les adresses IP seront différentes):
```
NAME                TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
msr-hello-world     LoadBalancer   10.0.172.191   108.143.83.141   80:30727/TCP   8h
```
On utilise ici un service de type Load balancer qui expose une IP externe. La colonne EXTERNAL-IP doit donc normalement contenir une adresse IP, qui est celle par le biais de laquelle on pourra appeler l'API du microservice.

A partir de là, on peut tester le microservice en appelant GET /greetings (en remplaçant IPAddress par l'adresse IP externe renvoyée par la commande précédente):
```
curl --location --request GET 'http://IPAddress/helloworld/greetings?name=toto' --header 'accept: application/json'  --header 'Authorization: Basic QWRtaW5pc3RyYXRvcjptYW5hZ2U='
```
La réponse renvoyée doit être celle-ci:
```
{"message":"Hello toto, great to have you here!"}
```

### Debugging du déploiement Kubernetes

TODO