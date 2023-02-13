# DevOpsApplicationChallenge
Geckosoft DevOps application challenge

## Applicazione scelta

L'applicazione che ho scelto per questa challenge è [Shiori](https://github.com/go-shiori/shiori), un bookmark manager 
scritto in Go.
Ho scelto questa applicazione perché è scritta in Go, un linguaggio che sto imparando da poco e con il quale volevo
iniziare a fare qualcosa di più serio. Inoltre la struttura del progetto è molto semplice e quindi mi sembrava un
ottimo punto d'inizio per questa challenge.

// TODO: aggiungere un po' di contesto e spiegazione della struttura dell'app

## Building the application from source

### Prerequisites

- [Go](https://golang.org/doc/install)
- [Docker engine](https://docs.docker.com/engine/install/)

### Building the application

Per compilare l'applicazione e costruire l'immagine Docker è necessario eseguire il comando:

```bash
docker build -t shiori .
```

in questo modo verrà compilata l'applicazione e verrà creata l'immagine Docker _shiori_ che potremo utilizzare per
avviare l'applicazione.
Per verificare che l'immagine sia stata creata correttamente possiamo lanciare il comando:

```bash
docker images
```

che ci mostrerà tutte le immagini presenti sul nostro sistema.
A questo punto non ci resta che eseguire l'immagine con il comando:

```bash
docker run -p 8080:8080 shiori 
```

Per caricare l'immagine dell'applicazione su un container registry (Docker Hub o GHCR) è necessario prima eseguire il
login attraverso un token.
Successivamente è possibile caricare l'immagine con il comando:

```bash
docker push <nome_immagine>
```

Dove il nome dell'immagine deve essere opportunamente dotato di tag.
Ad esempio per eseguire il push dell'immagine su GHCR:

```bash
docker built -t ghcr.io/<username>/<repository>:<tag> .

docker push ghcr.io/<username>/<repository>:<tag>
```

## Running the application locally

### Prerequisites

- [Docker Compose](https://docs.docker.com/compose/install/linux/)

### Running the application

Per eseguire l'applicazione con _Docker compose_ non occore fare altro che entrare nella directory _shiori-master_ dove
è contenuto tutto il codice sorgente dell'applicazione e insieme ad esso anche il file _docker-compose.yml_ e lanciare
il comando:

```bash
docker-compose up
```

Questo comando avvierà il container _shiori_ che eseguirà l'applicazione e il container _postgres_ che conterrà 
il database.
L'applicazione sarà disponibile all'indirizzo [http://localhost:8080](http://localhost:8080) e l'utente di default è
`shiori` con password `gopher`. 

Possiamo vedere i container creati con il comando:

```bash
docker ps
```

e controllare i log per ogni container con il comando:

```bash
docker logs <container_id>
```

Per fermare l'applicazione basta premere `Ctrl+C` e per rimuovere i container lanciare il comando:

```bash
docker kill <container_id>
```

e successivamente rimuovere il container con il comando:

```bash
docker rm <container_id>
```

o alternativamente stoppare e rimuovere tutti i container con:

```bash
docker compose down 
```

### Debugging the application

Per lanciare i servizi in modo separato e testarne il funzionamento è possibile lanciare il comando:

```bash
docker-compose up <nome_servizio>
```

con i nomi dei servizi che sono recuperabili dal file _docker-compose.yaml_.

Per esempio per lanciare solo il database:

```bash
docker-compose up postgres
```

// TODO altri comandi di debug/log

## Running the application on Kubernetes

### Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/)

### Deploying the application in minikube

Per eseguire l'applicazione su Kubernetes è necessario prima avviare il cluster con il comando:

```bash
minikube start
```

questo creeerà un cluster con un solo nodo e lo avvierà. Per verificare che il cluster sia stato avviato correttamente
possiamo lanciare il comando:

```bash
kubectl get nodes
```

To deploy the application we need to create a secret that will contain the credentials for the Docker registry.
In this case we will use the GitHub Container Registry (GHCR) so we need to create a secret with the following
command:

```bash
kubectl create secret docker-registry --dry-run=client ghcr-secret --docker-server=ghcr.io --docker-username=<username> --docker-password=<github_token> --docker-email=<github_email> -o yaml > docker-secret.yaml
```

This way we can keep the repository private and push the private image we created previously.
The name of the secret must be the same of the secret name in the _shiori.yaml_ file.

```YAML
      imagePullSecrets:
        - name: ghcr-secret
```

and we can change the image name in the _shiori.yaml_ file to the one we pushed to the registry.

```YAML
      containers:
        - name: shiori
          image: ghcr.io/<username>/<repository>:<tag>
```

Now we can deploy the application with the command:

```bash
kubectl apply -f shiori.yaml

kubectl apply -f docker-secret.yaml

kubectl apply -f postgres.yaml

kubectl apply -f mariadb.yaml
```

// TODO: usare LoadBalancer al posto di NodePort
Il _service.yaml_ file contiene la configurazione per esporre l'applicazione all'esterno del cluster. 
In particolare viene esposto il servizio _shiori_ all'indirizzo [http://<indirizzo_ip_nodo_minikube>:30080](http://192.168.49.2:30080)
recuperabile attraverso il comando:
    
```bash
kubectl get nodes -o wide
```

### Deploying the application in kind

// TODO

