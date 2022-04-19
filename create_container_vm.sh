#!/usr/bin/env bash

# Wrapper for creating Google Compute Engine container-optimzed OS machines
# the using gcloud CLI SDK.
#

RANDOM_HEX=$(printf "%04x" $RANDOM $RANDOM)
VERSION="0.1.0-alpha"

subcommand=$1;
case "$subcommand" in
  # Parse options to the subcommand
  $1)
    run=$1; shift  # Remove subcommand

    while getopts ":s:p:z:r:t:V:" opt; do
        case ${opt} in
            s)
                service_account=$OPTARG
                ;;
            p)
                project=$OPTARG
                ;;
            z)
                zone=$OPTARG
                ;;
            r)
                region=$OPTARG
                ;;
            t)
                token=$OPTARG
                ;;
            *)
                show_help
                ;;
        esac
    done
    shift $((OPTIND-1))
esac

PROJECT="${project}"
SERVICE_ACCOUNT="${service_account}"
REGION="${region:-us-central1}"
ZONE="${zone:-us-central1-a}"
REGISTRATION_TOKEN="$token"

# Help function
show_help() {
   echo
   echo "Wrapper for creating GCE container-optimized OS machines"
   echo
   echo "Syntax: ./create_container_vm.sh [s|p|z|r|t]"
   echo
   echo "Options:"
   echo
   echo "[-s]   Set Service Account email address - E.g., custom-sa@sample-project.iam.gserviceaccount.com"
   echo "[-p]   Set GCP project"
   echo "[-z]   Set GCP Compute zone. Must be a valid zone for region"
   echo "[-r]   Set GCP region"
   echo "[-t]   Set Registration Token for GitLab"
   echo
   echo "[-V]  Print version."
   echo
   echo "Usage:"
   echo
   echo -e "./create_container_vm.sh create \n\
        -z us-central1-a \n\
        -p prod-partner-a-176bffe6 \n\
        -s custom-sa@sample-project.iam.gserviceaccount.com \n\
        -r us-central1"
   echo
   return $?
}

create() {
    gcloud compute instances create-with-container gitlab-vm-test-$RANDOM_HEX \
        --container-image gitlab/gitlab-runner:latest \
        --container-mount-host-path="mount-path=/gitlab-runner-config,host-path=/etc/gitlab-runner,mode=rw"
        --project=$PROJECT \
        --zone=$ZONE \
        --image-family=cos-stable \
        --image-project=cos-cloud \
        --service-account=$SERVICE_ACCOUNT \
        --container-command="register" \
        --container-arg="--non-interactive" \
        --container-arg="--url \"https://gitlab.com\"" \
        --container-arg="--registration-token $REGISTRATION_TOKEN" \
        --container-arg="--template-config /tmp/test-config.template.toml" \
        --container-arg="--description \"gitlab-ce-ruby-2.7\"" \
        --container-arg="--executor docker" \
        --container-arg="--docker-image ruby:2.7"
    return $?
}

list() {
    gcloud compute instances list \
        --project=$PROJECT \
        --zones=$ZONE
    return $?
}

delete() {
    instance=$2
    gcloud compute instances delete $instance \
        --project=$PROJECT \
        --zone=$ZONE
    return $?
}

if [[ -n "$run" && "$run" != "" ]]; then 
    if [[ "$run" == "-h" ]]; then
        show_help
    elif
       [[ "$run" == "-V" ]]; then
        echo $VERSION
    else
        $run
    fi
fi