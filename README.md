# Devops Test

**! See below  the result**

### Overview
This is an application that is a dummy webservice that returns the
last update time.  The last updated time is cached in redis and
resets every 5 seconds.  It has a single '/' endpoint.  The redis
address is passed in through the environment.

NOTE: The following tasks are estimated to take no more than 3 hours total.

### Tasks
1. Create Dockerfile for this application
2. Create docker-compose.yaml to replicate a full running environment
so that a developer can run the entire application locally without having
to run any dependencies (i.e. redis) in a separate process.
3. Explain how you would monitor this application in production.
Please write code/scripts to do the monitoring.

### Kubernetes(MiniKube) Tasks
4. Prepare local Kubernetes environment (using MiniKube) to run our application in pod/container.
Store all relevant scripts (kubectl commands etc) in your forked repository.
5. Suggest & create minimal local infrastructure to perform functional testing/monitoring of our application pod.
Demonstrate monitoring of relevant results & metrics for normal app behavior and failure(s).

Please fork this repository and make a pull request with your changes.

Please provide test monitoring results in any convenient form (files, images, additional notes) as a separate archive.


# Result


## Run dockerized app with docker-compose (with Redis)

**prerequisites:**

1. before running docker-compose please create external network available between services (to let Monitoring and App to communicate) by running once:
```bash
docker network create cross-network
```

**run:**

from the project root folder run:
```bash
docker-compose up --build -d
```


## Run app with Kubernetes (Minikube)

**prerequisites:**

1. [Install Minikube](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)
2. enable ingress:
```bash
minikube addons enable ingress
```
3. push Docker image of the app to Dockerhub:
```bash
docker tag devops_test_faraway:latest creatiwww/devops_test_faraway:latest
docker push creatiwww/devops_test_faraway:latest
```

**run:**

apply k8s resourses
```bash
kubectl apply -f ./deploy
```
make sure the app is working by performing smoke test:
```bash
curl $(kubectl get ing -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}"):80
```
result should be like:
```bash
> hello world: updated_time=2022-03-08 09:03:59
```


## Run monitoring for docker-compose orchestrated app (Prometheus + Grafana stack)

**run:**

cd to the *monitoring* folder and run:
```bash
docker-compose up --build -d
```
make sure [Grafana](http://localhost:3000/) and [Prometheus](http://localhost:9090/) are up by opening them

**notes:**

 App and Redis containers as well as Monitoring are running at the same network called *cross-network*, both orchestrated by docker-compose


## Run monitoring for Kubernetes (Minikube) orchestrated app

**prerequisites:**

1. stop previously running Monitoring environment
```bash
docker-compose down
```
2. activate Minikube tunnel to get external IPs for Services with type = LoadBalancers running on Minikube (we use it to expose Redis and Go App metrics via exporter and go client library)
```bash
minikube tunnel
```
3. get external ip of the sidecar servise which Prometheus uses to scrape Redis metrics:
```bash
kubectl get services devops-test-redis-expose-service
```
4. get external ip of the servise which Prometheus uses to scrape Go App metrics:
```bash
kubectl get services services devops-test-go-metrics-expose-service
```
5. put obtained external IPs into the *monitoring/prometheus/prometheus.yml* file at target section for *redis-exporter* and *goapp* jobs:
```
- job_name: redis-exporter
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - '10.108.149.17:9121'
- job_name: goapp
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - '10.107.86.33:9000'
```

**run:**

cd to the *monitoring* folder and run:
```bash
docker-compose up --build -d
```
make sure [Grafana](http://localhost:3000/) and [Prometheus](http://localhost:9090/) are up by opening them


## Grafana dashboards configuration and checks

for monitoring purpose we will import pre-created by comunity doshboards for Redis and Go Apps (includes most of required metrics) by create->import->Load via URL:
* https://grafana.com/api/dashboards/763/revisions/3/download - Redis dashboard
* https://grafana.com/api/dashboards/6671/revisions/2/download - Grafana dashboard

*normal operating behavior:
..*Prometheus targets:
![Alt text](/images/prometheus-targets-ok.png")
..*Grafana Redis dashboard:
![Alt text](/images/redis-grafana-ok")
..*Grafana Go App dashboard:
![Alt text](/images/go-processes-grafana-ok")
*on failure:
..*Prometheus targets:
![Alt text](/images/prometheus-targets-error.png")
..*Grafana Redis dashboard:
![Alt text](/images/redis-grafana-error")
..*Grafana Go App dashboard:
![Alt text](/images/go-processes-grafana-error")

**notes:**
Grafana login/pass: admin/admin
