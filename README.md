# gcloud CLI SDK Documentation

This repo contains useful gcloud CLI SDK commands.

## Containerized GitLab Runner VM

```
Syntax: ./create_container_vm.sh [s|p|z|r|t|V|h]

Options:

[-s]   Set Service Account email address - E.g., custom-sa@sample-project.iam.gserviceaccount.com
[-p]   Set GCP project
[-z]   Set GCP Compute zone. Must be a valid zone for region
[-r]   Set GCP region
[-t]   Set Registration Token for GitLab
   echo
[-V]   Print version.
```

### Usage:

1. Ensure that you have a service account created to run the VM as. It does not require any special permissions.
2. Ensure that your `APPLICATION_DEFAULT_CREDENTIALS` are set to a user that has permission to create resources in the project you wish the GCE VM to reside in:
    ```
    gcloud auth
    gcloud auth application-default login
    ```
3. Run the following command:

```
./create_container_vm.sh create
        -z us-central1-a
        -p <project>
        -s custom-sa@sample-project.iam.gserviceaccount.com
        -r us-central1
```

### Firewall access

It is *highly* recommended that one removes all default firewall rules in the network that this GCE instance is running in. It is required that the VM have an external IP address so that GitLab's runner can access it. We should only allow SSH access via IAP:

```
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --project=<project>
```

### Running the runner

Once the runner has been registered, starting the the container is easy:

```
gcloud compute ssh --zone "us-central1-a" <instance name> --tunnel-through-iap --project <project> -- docker run --rm -v /etc/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner run
```
