This is a simple demo application that demonstrates how to dockerize a basic flask app and deploy it as a kubernetes application. 

## Testing locally

To create the necessary environment(minikube using docker) you can run the ```setup_minikube_indempotent.sh``` script, which will set up the following:
* install docker
* install minikube
* install kubectl

Once the script is run, it will tell you to either reconnect(in some cases with wsl profile requires reloading) or to simply start minikube with ```minikube start --driver=docker```. By default, minikube should link your kubectl profile to use its default namespace.

The image itself can be built by running ```docker build -t tet_task:latest docker_site/```

The image must then be loaded into minikube with ```minikube image load tet_task:latest```

It can then be applied to minikube by running ```kubectl apply -f site.k8s```

If you are running on WSL, you might need to enable port-forwarding by running ```kubectl port-forward svc/site-demo 8080:80```

note: This is different from the way in which the image is built and tested in the CI/CD pipeline, as much of the heavy lifting is done by github actions.

## Forking and testing pipeline

The pipeline is configured to build a local image, test if it deploys and runs on a mini temporary cluster on the runner, and then uploads the image to ghcr.io. It is built in such a way as to not require any github secret adjustments. Just fork the repository and run the pipeline.

## horizontal scaling
While it is possible to scale the application by runnig ```kubectl scale deployment site-demo --replicas=3```, you would ideally set it in the .k8s manifest by modifying the replicas count:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: site-demo
spec:
  replicas: 3
```

and simply re-apply the site.k8s manifest.

## security considerations
The container is set to use a non-root user, and the kubernetes deployment has a security context that does not permit privelige escalation and drops linux features. There are no further security measures taken with the individual container image, as those should be handled in their respective components(lb, firewall, security groups, rate limiting, etc) which this projects does not contain.

## decisions and assignment approach.
The assignment asked for a step that would deploy it to a _local_ kubernetes cluster, which I just cannot provide as I cant really host an open cluster, so I instead had it be tested in a temporary cluster in the pipeline, while providing the methods needed to deploy it to a local minikube closter. In a real world environment, this sort of deployment would ideally be handled with argocd or helm, and kubectl would be entirely bypassed or subsumed into the larger set of tooling.

As for the task itself, around 70% of the time was spent creating the setup_minikube_indempotent script, and debugging minikube in WSL.

There are likely many places in both the pipeline.yml and site.k8s that could have benfited from dynamic naming, but I decided to ignore it so that a basic fork of the repository would be enough to instantly run and test it.

Also, I didnt upload the image first and then run it from the image repository because that would mean that id either have to do it twice(one for first test, second for :latest tag) whereas now there is only one upload if the process succeeds.