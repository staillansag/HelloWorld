# microservice webMethods Hello World

Ce repository montre l'utilisation du Microservice Runtime Software AG pour mettre en place un microservice Hello World.
Deux configurations et deux modes de déploiement sont fournis:
-   configuration et déploiement simplifiés, sans dépendance externe à gérer
-   configuration standard, avec branchement aux ressources externes (et donc nécessité de configurer ces ressources externes)

## Architecture logique
![Architecture logique](resources/documentation/images/ArchitectureLogique.png)

## Gestion des dépendances

### Base de données webMethods

Cette base de données doit être configurée avec les schémas ISCoreAudit et ISInternal. On pourra utiliser l'outil Database Configurator pour ce faire.

Ce microservice s'appuie sur une base Postgres, mais grace au driver JDBC DataDirect Connect on peut utiliser d'autres solutions équivalentes (ou supérieures.)

Quatre variables d'environnement permettent de se connecter à cette base de données:
-   WM_DB_URL: URL JDBC de connexion à la base
-   WM_DB_USER: user pour se connecter à la base
-   WM_DB_PASSWORD: mot de passe pour se connecter à la base
-   WM_DB_DRIVER_ALIAS: alias du driver JDBC pour se connecter à la base

TODO: 
-   fournir une image du Database Configurator 
-   gérer l'initialisation des schémas avec un job Kubernetes

### Base de données du microservice

Le microservice se connecte à une base Postgres nommée sandbox, qui doit comporter une table helloworldmessages. Voici le DDL pour créer cette table:
```
CREATE TABLE public.hellomessages (
	id varchar(50) NOT NULL,
	creationdatetime timestamp NOT NULL,
	message varchar(255) NOT NULL
);
```

Voici les variables d'environnement à configurer pour se connecter à cette base:
-   DB_SERVERNAME: nom ou IP de la machine hébergeant la base
-   DB_PORT: port de communication de la base
-   DB_NAME: nom de la base
-   DB_USER: user pour se connecter à la base
-   DB_PASSWORD: mot de passe pour se connecter à la base
-   DATASOURCE_CLASS: classe du driver JDBC

### Universal Messaging

Le microservice utilise un realm Universal Messaging externe pour la communication orientée message.  
Il embarque deux fichiers de configuration:
-   jndi_DEFAULT_IS_JNDI_PROVIDER.properties qui définit le fournisseur JNDI pour se connecter au realm UM
-   jms.cnf qui définit l'alias de connection au realm UM nommé dce_JMS, lequel pointe vers une connection factory XA nommée um_cf_xa_nhps

La connection au realm se fait par le biais de la variable d'environnement JNDI_ALIAS_PROVIDERURL

Au sein du realm deux ressources doivent être définies:
-   la connection factory XA nommée um_cf_xa_nhps
-   le topic nommé HelloWorldTopic

TODO:
-   Déployer l'UM au sein du cluster Kubernetes (par le biais d'un StatefulSet)
-   Gérer la création des ressources de l'UM par le biais d'un job Kubernetes

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

Pour effectuer ce déploiement simplifié, il faut d'abord se positionner dans resources/kubernetes-test  

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

### Déploiement standard

TODO

### Debugging du déploiement Kubernetes

#### Statut du pod différent de "Running"

Utiliser la commande suivante pour investiguer (en remplaçant podName par le nom de pod renvoyé par la commande get pods):
```
kubectl describe pod podName -n dce
```

#### Erreur au niveau de l'appel d'API

Il peut y avoir plusieurs explications.

Commencez par vérifier les logs du microservice runtime avec cette commande (en remplaçant podName par le nom de pod renvoyé par la commande get pods):
```
kubectl logs podName -n dce
```
Il s'agit du contenu du fichier server.log, qui permet de savoir si le serveur est bien démarré.

Si le serveur MSR est bien démarré, le problème est peut-être au niveau du service. La commande suivante permet d'analyser ce service:
```
kubectl describe svc msr-hello-world -n dce
```
Voici le contenu attendu (les adresses IP seront différentes):
```
Name:                     msr-hello-world
Namespace:                dce
Labels:                   name=msr-hello-world
Annotations:              <none>
Selector:                 app=msr-hello-world
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.74.154
IPs:                      10.0.74.154
LoadBalancer Ingress:     20.126.68.228
Port:                     <unset>  80/TCP
TargetPort:               5555/TCP
NodePort:                 <unset>  31260/TCP
Endpoints:                10.244.0.32:5555
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  27m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   26m   service-controller  Ensured load balancer
```
Il faut vérifier la ligne "Endpoints", qui doit pointer vers une ou plusieurs IP de pods (en fonction du nombre de réplicas configuré) et sur le port 5555.

Une autre manière d'investiguer le problème est d'utiliser le port-forward, qui permet de créer un tunnel entre un pod et votre station de travail (en remplaçant podName par le nom de pod renvoyé par la commande get pods):
```
kubectl port-forward podName 8888:5555 -n dce
```
A partir de là, on peut essayer d'appeler l'API en pointant vers localhost:8888:
```
curl --location --request GET 'http://localhost:8888/helloworld/greetings?name=toto' --header 'accept: application/json'  --header 'Authorization: Basic QWRtaW5pc3RyYXRvcjptYW5hZ2U='
```
Dans le cas où cet appel renvoie la réponse attendue, alors le pod fonctionne correctement et problème est très certainement au niveau du service.
