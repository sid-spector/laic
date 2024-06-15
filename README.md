# welcome to laic !

Welcome to Lab61 Awsome Interactive Cluster!

## prerequisites
How to setup DO Spaces as the terraform backend. Use AWS cli to interact with DO:
- get a git repository
- install aws cli
- run `aws configure --profile digitalocean`
- setup credentials using a **space key** you can setup in the API tab of DO dashboard
- export `AWS_PROFILE=digitalocean`
- enjoy
- export a (fucking) DO token for auth: `export DIGITALOCEAN_TOKEN=`

## howto

### terraform

In order to apply the terraform you must configure the variables exposed in `k8s-configuration/variables.tf`

- `ssh_key_path`: the relative path of an ssh private key that must be configured to access the repository

- `repo_url`: the url of the git repository 

In order to enjoy the fun just get into the `k8s-configuration` folder and run

`tofu init`
`tofu apply`


### gitops

Before applying the gitops repository you need to substitute 
* `##YOUR_GIT_REPO##` with url of your repository 
* `##YOUR_HOST###` with your host
* `##YOUR_ACME_EMAIL###` with the email address you want to use for ACME registration
* JICOFO_AUTH_USER JVB_AUTH_USER and relative passwords and secrets in `application/jitsi-meet/templates/all.yaml`

and **push** the commit to the main branch of your repository.

## access argocd

You can later access the argocd config thing:

`kubectl get secret argocd-initial-admin-secret -o yaml -n argocd --kubeconfig kubeconfig | grep password | cut -d ':' -f 2 | tr -d ' ' | base64 -d`

Take note of the passowrd

Then:

`kubectl port-forward svc/argocd-server -n argocd 8080:443 -n argocd --kubeconfig kubeconfig`


## sync

applications and their definition must be synced on a given order, you can easly figure it out by yourself or guessing following the syncwave numbers. This will be fixed, hopefully not before you understood it.

BAM!


 
