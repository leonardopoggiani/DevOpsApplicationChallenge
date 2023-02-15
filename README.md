# DevOpsApplicationChallenge

## Geckosoft DevOps application challenge

## Choosen application

The application I chose for this challenge is [Shiori](https://github.com/go-shiori/shiori), a bookmark manager
written in Go.
I chose this application because it is written in Go, a language I am just learning and with which I wanted to
start doing something more serious. Also, the structure of the project is very simple, so it seemed like a
great place to start for this challenge.

### Application structure

Shiori is a bookmark manager that allows you to save links to your favorite websites and access them easily and
even offline if necessary.
The application is written in Go with the main components found within the _internal/_ folder.
The application use a PostgreSQL and a MariaDB database to store the bookmarks and the user credentials. There is also
webapp written in Vue.js that is used to interact with the application.

The files with the deployments I created are found inside the _deploy/_ folder and the _terraform/_ folder.
I did not significantly modify the application code (just a few dependencies or a few lines for convenience).

## Building the application from source

### Prerequisites

- [Go](https://golang.org/doc/install)
- [Docker engine](https://docs.docker.com/engine/install/)

### Building the application

To compile the application and build the Docker image, it is necessary to run the command:

```bash
docker build -t shiori .
```

this will compile the application and create the Docker _shiori_ image that we can use to
start the application.
To verify that the image was created correctly we can run the command:

```bash
docker images
```

which will show us all the images on our system.
At this point all we have to do is run the image with the command:

```bash
docker run -p 8080:8080 shiori 
```

In order to upload the application image to a container registry (Docker Hub or GHCR), it is first necessary to perform a
login through a token. ([docker login](https://docs.docker.com/engine/reference/commandline/login/) command)
Then you can upload the image with the command:

```bash
docker push <nome_immagine>
```

Where the image name must be appropriately tagged.
For example, to push the image to GHCR:

```bash
docker built -t ghcr.io/<username>/<repository>:<tag> .

docker push ghcr.io/<username>/<repository>:<tag>
```

## Running the application locally

### Prerequisites

- [Docker Compose](https://docs.docker.com/compose/install/linux/)

### Running the application

To run the application with _Docker compose_ all you need to do is enter the _shiori-master_ directory where
is contained all the source code of the application and along with it the file _docker-compose.yml_ and run
the command:

```bash
docker-compose up
```

This command will start the _shiori_ container that will run the application and the _postgres_ and _mariadb_ containers
that will contain the database.
The application will be available at [http://localhost:8080](http://localhost:8080) and the default user is
`shiori` with password `gopher`.

We can see the containers created with the command:

```bash
docker ps
```

and check the logs for each container with the command:

```bash
docker logs <container_id>
```

To stop the application just press `Ctrl+C` and to remove containers run the command:

```bash
docker kill <container_id>
```

and then remove the container with the command:

```bash
docker rm <container_id>
```

Or alternatively stop and remove all containers with:

```bash
docker compose down 
```

### Debugging the application

To launch the services separately and test their operation, you can run the command:

```bash
docker-compose up <nome_servizio>
```

with the names of the services that are retrievable from the _docker-compose.yaml_ file.

For example to launch only the database:

```bash
docker-compose up postgres
```

## Running the application on Kubernetes

### Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Deploying the application in minikube

To run the application on Kubernetes, you must first start the cluster with the command:

```bash
minikube start
```

this will create a cluster with only one node and start it. To verify that the cluster has been started correctly
we can run the command:

```bash
kubectl get nodes
```

(NOTE: this is valid only if the repository is private and so you can't push/pull images without secrets)
To deploy the application we need to create a secret that will contain the credentials for the Docker registry.
In this case we will use the GitHub Container Registry (GHCR) so we need to create a secret with the following
command:

```bash
kubectl create secret docker-registry --dry-run=client ghcr-secret --docker-server=ghcr.io --docker-username=<username> --docker-password=<github_token> --docker-email=<github_email> -o yaml > dockerSecret.yaml
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

Now we can deploy the application with the commands:

```bash
kubectl apply -f shiori.yaml

kubectl apply -f dockerSecret.yaml

kubectl apply -f postgres.yaml

kubectl apply -f mariadb.yaml

kubectl apply -f service.yaml

```

or just with:

```bash
kubectl apply -f minikube/single-enviroment
```

// TODO: utilize LoadBalancer instead of NodePort

By using a LoadBalancer instead of a NodePort, it is possible to expose the application outside the cluster through a
single IP address without worrying about having to retrieve the node address or port number each time
(the number of ports that can be used is limited, so in large deployments it may not be sufficient).
A simple load balancer that can be used is [MetalLB](https://metallb.universe.tf/) or [OpenELB](https://openelb.io/).

The _service.yaml_ file contains the configuration for exposing the application outside the cluster.
Specifically, the _shiori_ service is exposed at the address [http://<ip_address_node_minikube>:30080](http://192.168.49.2:30080)
retrievable through the command:

```bash
kubectl get nodes -o wide
```

#### Using an external database

To use an external database we need to change the _shiori.yaml_ file. We need to change the secrets that we use to 
define the environment variables. In particular the _SHIORI_DBMS_ will be the hostname or the ip address for the 
database server and so on.

### Deploying the application in kind

// TODO 

The deployment process is almost the same of minikube but kind allow us to create a cluster with multiple nodes. This way we 
can simulate the deployment of the application on multiple nodes.

## Deploying the application on two isolated environments

We can deploy the application to two separate environments (QA and PRODUCTION) by leveraging the namespaces of
which allow us to maintain two isolated environments within the same cluster (alternatively we could create
two separate clusters which is definitely the best practice if maintenance costs and cluster size
are not an issue). The [logical separation](https://learn.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-isolation#logically-isolate-clusters) 
of clusters usually provides higher pod density than physically isolated clusters, with less compute overhead.

We first create the respective configuration files for the namespaces in this way:

```bash
apiVersion: v1
kind: Namespace
metadata:
  name: <namespace_name>
  labels:
    name: <namespace_name>
```
and then we create the environments with the command:

```bash
kubectl apply -f <namespace_name>.yaml
```

From now on when we want to perform a particular action on a namespace we have to specify which one
it is by adding the parameter `-n <namespace_name>` and each _kubectl_ command.

```bash
kubectl apply -f single-environment/ -n <namespace_name>
```

To avoid forgetting or using the wrong parameter we can set the namespace in the configuration file
like this:

```YAML
    metadata:
      name: shiori-qa
      namespace: quality-assurance
```

and then we can just execute:

```bash
kubectl apply -f multi-environment/
```

to automatically deploy to two isolated environments in this way we can specify different parameters for
each of the two environments. For example, we can specify a different replication number for each environment:

```YAML
    spec:
      replicas: 2
```

We could also specify a service of type _LoadBalancer_ for the production environment so that we can access
the application from outside the cluster while for the QA environment we could use a service of type _NodePort_.
Also in this way we can specify a different database for each environment. Obviously in this case we need to
first create the two separate databases and then specify the respective connection parameters.

## Configuring RBAC

// TODO

As an alternative to this method (who doesn't happen to forget the parameter?) we can set the default namespace
by going to define two different contexts in this way:
    
```bash
kubectl config set-context qa --namespace=quality-assurance --cluster=minikube --user=<username>
```

If you want you can also define different users by specifying the `--username` parameter as you prefer and then set a password
using:

```bash
kubectl config set-credentials <role> --username=<username> --password=<password>
```

In order to use the context at this point we need to go and define the new user (if not already defined). In
this way we are able to restrict access to cluster resources to only those with the necessary permissions.

## Log events 

### Pre-requisites

- [Helm](https://helm.sh/docs/intro/install/)

### Deploying Prometheus

To use Prometheus as an event logger we can deploy with the Helm chart or (if we want  more configurability) we can
deploy with the _prometheus.yaml_ configuration file.
In this case we must first create the _monitoring_ namespace and then deploy the configuration file.
The deployment of Prometheus can be done in a simplified way by going to use the Helm package manager:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring
```

We can check the status of the deployment with the command:

```bash
kubectl get pods -n monitoring
```

At this point we can try to access the Prometheus dashboard at [http://localhost:9090](http://localhost:9090)
using the command:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090
```

which allows us to access the Prometheus UI on the localhost.
To access the Grafana dashboard we can use the command:

```bash
kubectl get secret -n monitoring monitoring-grafana -o yaml
```

which allows us to retrieve the password to access the Grafana dashboard.
Having decoded the password and username we can run the command:

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3001:80
``` 

to access the Grafana dashboard at [http://localhost:3001](http://localhost:3001).
To add new metrics in addition to the Kubernetes system metrics, we can add annotations to the services on which 
Prometheus is to do scraping (not present in the official documentation, may not work)

```YAML
    annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/port: '9187'
      prometheus.io/path: '/metrics'
      prometheus.io/scheme: 'http'
```

### Deploying Kibana

To deploy Kibana we use the configuration files in the _multi-environment/kibana/_ folder.
We can simply run the command:

```bash
kubectl apply -f multi-environment/kibana/
```

We must then enable port-forwarding to access the Kibana dashboard at [http://localhost:5601](http://localhost:5601):

```bash
kubectl port-forward <kibana-pod-name> 5601:5601 --namespace=monitoring
```

At this point from the Kibana dashboard we can create a new index for Shiori's logs. To do this we go
to the _Discovery_ section and follow the steps in the configuration wizard.

## (Bonus task 1) Running CI service to test the application

One method to deploy Jenkins in a scalable way is definitely to do it within the cluster created
with Kubernetes.
To deploy Jenkins within the Kubernetes cluster, we must first create a namespace:

```bash
kubectl create namespace devops-tools
```

Then we can deploy Jenkins with the configuration file in the _multi-environment/jenkins/_ folder:

```bash
kubectl apply -f multi-environment/jenkins/
```

this way we will have a Jenkins installation complete with all the dependencies needed to run the CI/CD and
reachable from the browser at [http://<minikube_ip>:30000](http://<minikube_ip>:30000).

Alternatively, we can [install]((https://www.jenkins.io/doc/book/installing/) the Jenkins server on the local system 
and reach it at [http://localhost:9090](http://localhost:9090).
After installing Jenkins we can configure it by accessing the dashboard and following the steps of the
[configuration wizard](https://www.jenkins.io/doc/book/installing/#setup-wizard).
Keep in mind that to configure Jenkins in a private repository a token has to be created through GitHub and the repository
corresponding should be referred to as _https://<token_github>@github.com/username/repository.git_.
Attention should be paid to the deployment mode of Jenkins because if it is run inside the Kubernetes cluster, 
and we want the pipeline to run inside a pod we need to specify the pod configuration:

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

Which must be entered as the agent in the pipeline otherwise you can leave indicated agent _any_ which will run the pipeline
on any worker node including the localhost.

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

After that, the various stages that will make up the pipeline in this particular case must be specified:

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

To run the pipeline we need to go to the Jenkins dashboard, create a new project and configure it with the necessary 
parameters. In particular, we will need to specify the repository where the source code is located that we
will need to run the pipeline and the branch to checkout from and later to automate the testing of the QA branch.

## (Bonus task 2) Deploying the application using Terraform

### Pre-requisites

- [Terraform](https://www.terraform.io/downloads.html)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install?hl=it) or any other cloud provider

### Deploying the application

To deploy the application to GCP we can use Terraform.
First we need to create a project on GCP and enable the API needed for deployment. Then moving to the project folder 
should be initilized with the command:

```bash
terraform init
```

after which you need to write the _deploy.tf_ file:
as _required_provider_ should be entered the cloud provider you intend to use (GCP in this case) and you
enter information such as the project id, project name, and the region to be used.

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

After that, the resources to be created should be specified, for example, a network with associated subnetworks and a
firewall to allow inbound and outbound traffic.
Having defined the VM instances to be run and the related image, one can specify the commands to be executed on each
instance:

```Terraform
metadata_startup_script = <<-SCRIPT
    # Install dependencies
    apt-get update
    apt-get install -y curl git
    ...
```

where we can, for example, clone the repository of our project and install it on the newly created instance.

### Deploying the cluster 

Inside the _terraform_ folder are the files that are needed to create a cluster on GCP.

## (Bonus task 3) Monitors and deploy code in GitHub repository

### Pre-requisites

- [ngrok](https://ngrok.com/download) (only if Jenkins is running on localhost)

### Create GitHub webhook

For this task, GitHub Webhooks can be used to trigger a Jenkins job on each push to a repository.
Specifically in the repository settings you go to the _Webhooks_ section and create a new webhook that has
as the URL the address of the Jenkins server and as the event type _Push_ (http://<server_jenkins>/github-webhook/).
If the Jenkins server is running within the Kubernetes cluster then we are going to enter the address of the node
minikube instead of that of the Jenkins server.

If the Jenkins server is running on the localhost then we are going to download [ngrok](https://ngrok.com/download) that
can expose our localhost to the Internet and create a tunnel between the two. And at this point you can create the 
webhook using the address provided by ngrok (http://<ngrok_url>/github-webhook/).

