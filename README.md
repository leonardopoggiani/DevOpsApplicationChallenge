# DevOpsApplicationChallenge

## Geckosoft DevOps application challenge

## Applicazione scelta

L'applicazione che ho scelto per questa challenge è [Shiori](https://github.com/go-shiori/shiori), un bookmark manager 
scritto in Go.
Ho scelto questa applicazione perché è scritta in Go, un linguaggio che sto imparando da poco e con il quale volevo
iniziare a fare qualcosa di più serio. Inoltre la struttura del progetto è molto semplice e quindi mi sembrava un
ottimo punto d'inizio per questa challenge.

### Struttura dell'applicazione

Shiori è un bookmark manager che permette di salvare i link ai siti web preferiti e di accedervi in modo semplice e 
anche in offline se necessario. 
L'applicazione è scritta in Go con i componenti principali presenti all'interno della cartella _internal/_.
The application use a PostgreSQL and a MariaDB database to store the bookmarks and the user credentials. There is also 
webapp written in Vue.js that is used to interact with the application.

I file con i deployment che ho creato si trovato all'interno della cartella _deploy/_ e della cartella _terraform/_.
Non ho modificato in modo significativo il codice dell'applicazione (solo qualche dipendenza o qualche riga per comodità).

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

kubectl apply -f service.yaml

```

or just with:

```bash
kubectl apply -f minikube/single-enviroment
```

// TODO: usare LoadBalancer al posto di NodePort 

Usando un LoadBalancer al posto di un NodePort è possibile esporre l'applicazione all'esterno del cluster attraverso un 
unico indirizzo IP senza preoccuparti di dover recuperare l'indirizzo del nodo o il numero della porta ogni volta
(il numero delle porte utilizzabili è limitato e quindi in deployment di grandi dimensioni potrebbe non essere
sufficiente).

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

## Configuring RBAC

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

Per poter utilizzare il contesto a questo punto dobbiamo andare a definire il nuovo utente (se non già definito). In 
questo modo riusciamo a limitare l'accesso alle risorse del cluster solo a chi ha i permessi necessari.

## Log events 

### Pre-requisites

- [Helm](https://helm.sh/docs/intro/install/)

### Deploying Prometheus

Per usare Prometheus come logger di eventi possiamo fare il deploy con il chart Helm oppure (se vogliamo una 
maggiore configurabilità) possiamo fare il deploy con il file di configurazione _prometheus.yaml_. 
In questo caso dobbiamo prima creare il namespace _monitoring_ e poi fare il deploy del file di configurazione.
Il deploy di Prometheus può essere fatto in modo semplificato andando a usare il gestore di pacchetti Helm:

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

## (Bonus task 1) Running CI service to test the application

Un metodo per fare il deploy di Jenkins in modo scalabile e' sicuramente quello di farlo all'interno del cluster creato 
con Kubernetes.
Per deployare Jenkins all'interno del cluster Kubernetes dobbiamo innanzitutto creare un namespace:

```bash
kubectl create namespace devops-tools
```

Quindi possiamo eseguire i file di configurazione nella cartella _multi-environment/jenkins_:

```bash
kubectl apply -f multi-environment/jenkins/
```

in questo modo avremo un'installazione di Jenkins completa di tutte le dipendenze necessarie per eseguire il CI/CD e
raggiungibile dal browser all'indirizzo [http://<minikube_ip>:30000](http://<minikube_ip>:30000).

Alternativamente possiamo [installare]((https://www.jenkins.io/doc/book/installing/) il server Jenkins nel sistema locale e raggiungerlo all'indirizzo [http://localhost:9090](http://localhost:9090).
Dopo aver installato Jenkins possiamo configurarlo accedendo alla dashboard e seguendo i passaggi della 
[configurazione guidata](https://www.jenkins.io/doc/book/installing/#setup-wizard).
Da ricordare che per configurare Jenkins in una repository privata va creato un token attraverso GitHub e la repository
corrispondente va indicata come _https://token_github@github.com/username/repository.git_.
Va prestata attenzione alla modalità di deploy di Jenkins perché se viene eseguito all'interno del cluster Kubernetes 
e vogliamo che la pipeline venga eseguita all'interna di un pod dobbiamo specificare la configurazione del pod:

```YAML
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        app: shiori-pipeline
    spec:
      containers:
      - name: golang
        image: golang:1.20.1
```

Che va inserito come agente nella pipeline altrimenti si può lasciare indicato l'agente _any_ che eseguirà la pipeline 
su qualsiasi nodo worker compreso il localhost.

```Groovy
pipeline {
  agent {
    kubernetes {
        yaml """
        ...
        """
    }
  }
  ...
```

Dopo di che vanno specificati i vari stage che comporranno la pipeline in particolare in questo caso:

```Groovy
stages {
    stage('Download dependencies') {
      ...
    }
    
    stage('Build') {
      ...
    }
    
    stage('Test') {
      ...
    }
    
    ...
```

Per eseguire la pipeline dobbiamo andare sulla dashboard di Jenkins, creare un nuovo progetto e configurarlo
con i parametri necessari. In particolare dovremo specificare il repository dove è presente il codice sorgente che ci 
servirà per eseguire la pipeline e il branch da cui fare il checkout e in seguito per automatizzare il testing del
branch QA.

## (Bonus task 2) Deploying the application using Terraform

### Pre-requisites

- [Terraform](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install?hl=it) or any other cloud provider

### Deploying the application

Per fare il deploy dell'applicazione su GCP possiamo utilizzare Terraform.
Per prima cosa dobbiamo creare un progetto su GCP e abilitare le API necessarie per il deploy. In seguito spostandosi
sulla cartella del progetto va initilizzato con il comando:

```bash
terraform init
```

dopo di che occorre scrivere il file _deploy.tf_:

-   come _required_provider_ va inserito il Cloud provider che si intende utilizzare (GCP in questo caso) e si 
inseriscono informazioni come il project id, il nome del progetto e la regione da utilizzare. 

```Terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = "<project_id>"
  region  = "europe-west3"
}
```

Dopo di che vanno specificate le risorse che si intende creare ad esempio una rete con le relative subnetworks e un 
firewall per permettere il traffico in ingresso e in uscita.
Definite le istanze di VM da eseguire e l'immagine relativa si possono specificare i comandi da eseguire su ciascuna 
istanza:

```Terraform
metadata_startup_script = <<-SCRIPT
    # Install dependencies
    apt-get update
    apt-get install -y curl git
    ...
```

dove possiamo ad esempio clonare la repository del nostro progetto e installarla sull'instanza appena creata.

### Deploying the cluster 

All'interno della cartella _terraform_ sono presenti i file che servono per creare un cluster su GCP.

## (Bonus task 3) Monitors and deploy code in GitHub repository

### Pre-requisites

- [ngrok](https://ngrok.com/download) (only if Jenkins is running on localhost)

### Create GitHub webhook

Per questo task si possono utilizzare i Webhook di GitHub per triggerare un job Jenkins ad ogni push su una 
repository.
In particolare nelle impostazioni della repository si va nella sezione _Webhooks_ e si crea un nuovo webhook che abbia 
come URL l'indirizzo del server Jenkins e come tipo di evento _Push_ (http://<server_jenkins>/github-webhook/).
Se il server Jenkins è eseguito all'interno del cluster Kubernetes allora andremo ad inserire l'indirizzo del nodo 
minikube al posto di quello del server Jenkins.

Se il server Jenkins è eseguito sul localhost allora andremo a scaricare [ngrok](https://ngrok.com/download) that can 
expose our localhost to the internet and create a tunnel between the two. E a questo punto si può creare il webhook 
usando l'indirizzo fornito da ngrok (http://<ngrok_url>/github-webhook/).

