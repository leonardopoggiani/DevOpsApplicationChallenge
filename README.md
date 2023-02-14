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

or just with:

```bash
kubectl apply -f minikube/single-enviroment
```

// TODO: usare LoadBalancer al posto di NodePort
Il _service.yaml_ file contiene la configurazione per esporre l'applicazione all'esterno del cluster. 
In particolare viene esposto il servizio _shiori_ all'indirizzo [http://<indirizzo_ip_nodo_minikube>:30080](http://192.168.49.2:30080)
recuperabile attraverso il comando:
    
```bash
kubectl get nodes -o wide
```

#### Using an external database

To use an external database we need to change the _shiori.yaml_ file. We need to change the secrets that we use to 
define the environment variables. In particular the _SHIORI_DBMS_ will be the hostname or the ip address for the 
database server and so on.

### Deploying the application in kind

// TODO

## Deploying the application on two isolated environments

Possiamo fare il deploy dell'applicazione su due ambienti separati (QA e PRODUCTION) sfruttando i namespace di 
che ci consentono di mantenere due ambienti isolati all'interno dello stesso cluster (alternativamente potremmo creare
due cluster separati che è sicuramente la best practice se i costi di mantenimento e la dimensione del cluster 
non sono un problema). [Logical separation](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-isolation#logically-isolate-clusters) of clusters usually provides a higher pod density than physically isolated 
clusters, with less excess compute capacity sitting idle in the cluster. When combined with the Kubernetes cluster 
autoscaler, you can scale the number of nodes up or down to meet demands. This best practice approach to autoscaling
minimizes costs by running only the number of nodes required.

Per prima cosa creiamo i rispettivi file di configurazione per i namespace in questo modo:

```bash
apiVersion: v1
kind: Namespace
metadata:
  name: <nome_ambiente>
  labels:
    name: <nome_ambiente>
```
e creiamo i namespace con il comando:

```bash
kubectl apply -f <nome_ambiente>.yaml
```

Da questo momento in poi quando vogliamo eseguire una particolare azione su un namespace dobbiamo specificare di quale 
si tratta aggiungendo il parametro `-n <nome_ambiente>` and ogni comando _kubectl_.

```bash
kubectl apply -f single-environment/ -n <nome_ambiente>
```

Per evitare di dimenticarci o di usare il parametro sbagliato possiamo impostare il namespace nel file di configurazione 
in questo modo:

```YAML
    metadata:
      name: shiori-qa
      namespace: quality-assurance
```

e quindi eseguire il comando:

```bash
kubectl apply -f multi-environment/
```

per eseguire il deploy in automatico su due ambienti isolati in questo modo possiamo specificare parametri diversi per 
ognuno dei due ambienti. Ad esempio possiamo specificare un diverso numero di replica per ogni ambiente:

```YAML
    spec:
      replicas: 2
```
Potremmo inoltre specificare un servizio di tipo _LoadBalancer_ per l'ambiente di produzione così da poter accedere 
all'applicazione dall'esterno del cluster mentre per l'ambiente di QA potremmo usare un servizio di tipo _NodePort_.
Inoltre in questo modo possiamo specificare un diverso database per ogni ambiente. Ovviamente in questo caso dobbiamo
prima creare i due database separati e poi specificare i rispettivi parametri di connessione.

// TODO
In alternativa a questo metodo (a chi non capita di scordarsi il parametro?) possiamo impostare il namespace di default 
andando a definire due diversi contesti in questo modo:
    
```bash
kubectl config set-context qa --namespace=quality-assurance --cluster=minikube --user=minikube
```

If you want you can also define diffent users by specifying the `--user` parameter as you prefer and then set a password
using:

```bash
kubectl config --kubeconfig=config-demo set-credentials experimenter --username=exp --password=some-password
```

## Log events 

### Pre-requisites

- [Helm](https://helm.sh/docs/intro/install/)

### Deploying Prometheus

Per usare Prometheus come logger di eventi possiamo fare il deploy con il chart Helm oppure (se vogliamo una 
maggiore configurabilità) possiamo fare il deploy con il file di configurazione _prometheus.yaml_. 
In questo caso dobbiamo prima creare il namespace _monitoring_ e poi fare il deploy del file di configurazione.
Il deploy di Prometheus può essere fatto in modo semplificato andando ad usare il gestore di pacchetti Helm:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring
```

Possiamo controllare che il deployment sia andato a buon fine con il comando:

```bash
kubectl get pods -n monitoring
```

A questo punto possiamo provare ad accedere alla dashboard di Prometheus all'indirizzo [http://localhost:9090](http://localhost:9090)
utilizzando il comando:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090
```

che ci consente di accedere la UI di Prometheus sul localhost.
Per accedere alla dashboard di Grafana possiamo utilizzare il comando:

```bash
kubectl get secret -n monitoring monitoring-grafana -o yaml
```

che ci consente di recuperare la password per accedere alla dashboard di Grafana.
Decodificata la password e l'username possiamo eseguire il comando:

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3001:80
``` 

per accedere alla dashboard di Grafana all'indirizzo [http://localhost:3001](http://localhost:3001).
Per aggiungere nuove metriche oltre a quelle di sistema di Kubernetes possiamo aggiungere delle annotazioni ai servici 
su cui Prometheus deve fare scraping ():

```YAML
    annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/port: '9187'
      prometheus.io/path: '/metrics'
      prometheus.io/scheme: 'http'
```

### Deploying Kibana

Per fare il deploy di Kibana utilizziamo i file di configurazione presenti nella cartella _multi-environment/kibana/_.
Possiamo semplicemente eseguire il comando:

```bash
kubectl apply -f multi-environment/kibana/
```

Dobbiamo poi abilitare il port-forwarding per accedere alla dashboard di Kibana all'indirizzo [http://localhost:5601](http://localhost:5601):

```bash
kubectl port-forward <kibana-pod-name> 5601:5601 --namespace=monitoring
```

A questo punto dalla dashboard di Kibana possiamo creare un nuovo indice per i log di Shiori. Per farlo andiamo
nella sezione _Discovery_ e seguiamo i passaggi della configurazione guidata.