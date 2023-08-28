# Setup de l'environnement de développement avec Docker compose

Ce script Docker compose déploie une base de données Postgres, un realm Universal Messaging et un MSR de développement avec les packages Monitor, JDBC Adapter, HDFS et Cloudstreams AWS S3.

##  Configuration

Le script Docker Compose pointe vers un fichier de configuration .env
Comme ce fichier contient certaines informations confidentielles, il n'est pas positionné dans git.
A la place j'ai positionné un exemple de ce fichier: env.example
Vous pouvez l'utiliser pour créer votre fichier .env, qui doit être positionné dans le même répertoire que le fichier docker-compose.yaml

##  Lancement

C'est un lancement Docker compose on ne peut plus classique:
```
docker-compose up -d
```
Dans certains systèmes, la commande docker-compose est à remplacer par "docker compose" (sans le tiret.)

Au premier lancement, le MSR va émettre des erreurs car les bases de données et l'UM n'ont pas encore été initialisés.

##  Initialisation de la base de données webMethods

La base wm est créée au moment de la création du conteneur postgresql, il reste à créer le user wm et lui accorder les habilitations adéquates.

```
docker exec -it postgresql psql -U postgres -c "CREATE USER wm WITH PASSWORD 'wm';"
docker exec -it postgresql psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE wm TO wm;"
docker exec -it postgresql psql -U postgres -d wm -c "GRANT ALL ON SCHEMA public TO wm;"
docker exec -it postgresql psql -U postgres -d wm -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO wm;"
```

Ensuite il reste à créer les tables webMethods.
Plutôt que d'installer le database configurator, on va l'utiliser par le biais d'une image Docker.
A noter qu'il faut bien prendre soin d'exécuter cette commande dans le réseau dce_sag, pour que le database configurator s'exécutant dans Docker puisse "parler" avec le conteneur Postgres qui se trouve dans ce réseau.

```
docker run -it --network dce_sag staillansag/dbc:10.15.0.1 /opt/softwareag/common/db/bin/dbConfigurator.sh -a create -d pgsql -c ISInternal,DocumentHistory,CrossReference,ISCoreAudit,DistributedLocking,ProcessAudit -v latest -l 'jdbc:wm:postgresql://postgresql:5432;databaseName=wm' -u wm -p wm
```

##  Initialisation de la base de données du microservice

Pour simplifier, on utilise le même user wm, mais on crée une nouvelle base de données sandbox.

On commence par créer la base.
```
docker exec -it postgresql psql -U postgres -c "CREATE DATABASE sandbox;"
```

Ensuite on habilite le user wm
```
docker exec -it postgresql psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE sandbox TO wm;"
docker exec -it postgresql psql -U postgres -d sandbox -c "GRANT ALL ON SCHEMA public TO wm;"
docker exec -it postgresql psql -U postgres -d sandbox -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO wm;"
```

Enfin on crée la table utilisé par le microservice Hello World
```
docker exec -it postgresql psql -U postgres -d sandbox -c "CREATE TABLE public.hellomessages (id varchar(50) NOT NULL, creationdatetime timestamp NOT NULL, message varchar(255) NOT NULL);"
```

##  Initialisation de Universal Messaging

Il nous faut créer la connection factory et le topic JMS.
Là aussi, on passe par un utilitaire packagé dans une image Docker, et disponible sur containers.softwareag.com

```
docker run -it --network dce_sag sagcr.azurecr.io/universalmessaging-tools:10.15 runUMTool.sh CreateConnectionFactory -rname=nsp://umserver:9000 -factoryname=um_cf_xa_nhps -factorytype=xa -connectionurl=nsp://umserver:9000
docker run -it --network dce_sag sagcr.azurecr.io/universalmessaging-tools:10.15 runUMTool.sh CreateJMSTopic -rname=nsp://umserver:9000 -channelname=HelloWorldTopic
```

##  Vérification du setup

Une fois les initialisation effectuées, il faut redémarrer le MSR.
```
docker restart msrdce
```

Une fois le MSR redémarré, on peut se connecter à la console d'admin (http://localhost:15555) pour vérifier que tout fonctionne:
-   Tous les packages sont activés (y compris le package HelloWorld)
-   Dans messaging, JDNI settings, lookup JNDI OK
-   Toujours dans Messaging, dans JMS settings, alias dce_JMS enabled
-   Dans External Servers --> SFTP --> User alias settings --> lookup de sftp_user OK
-   Solutions --> Cloudstreams > Amazon --> Amazon Simple Storage Service (S3) (AWS4) --> connexion "HelloWorld.aws:pocsag" enabled
-   JDBC adapters --> HelloWorld.jdbc:HelloWorld_jdbc enabled
-   Settings --> JDBC Pools --> lookup du pool "wmdb" OK
-   Section Monitoring fonctionnelle

##  Raccordement du Designer

Si tout les contrôles sont OK, on peut terminer le setup par le raccordement du MSR.
On raccorde le MSR comme on le fait avec un IS classique.
