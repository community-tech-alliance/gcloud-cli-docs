#!/usr/bin/env bash

# Wrapper for creating Google Compute Engine container-optimzed OS machines
# the using gcloud CLI SDK.
#

RANDOM_HEX=$(printf "%04x" $RANDOM $RANDOM)
VERSION="0.1.1-beta"

subcommand=$1
case $subcommand in
  $1)
    run=$1; shift #remove subcommand

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

PROJECT="$project"
SERVICE_ACCOUNT="${service_account}"
REGION="$region"
ZONE="$zone"
REGISTRATION_TOKEN="$token"

# Help function
show_help() {
   echo
   echo "Wrapper for creating GCE container-optimized OS machines"
   echo
   echo "Syntax: ./create_container_vm.sh [s|p|z|r|t|V]"
   echo
   echo "Options:"
   echo
   echo "[-s]   *Optional* Set Service Account email address - E.g., custom-sa@sample-project.iam.gserviceaccount.com"
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
    gcloud compute instances create-with-container gitlab-vm-$RANDOM_HEX \
        --container-image gitlab/gitlab-runner:latest \
        --container-mount-host-path="mount-path=/etc/gitlab-runner-config,host-path=/etc/gitlab-runner,mode=rw" \
        --container-mount-host-path="mount-path=/tmp,host-path=/tmp,mode=rw" \
        --project=$PROJECT \
        --zone=$ZONE \
        --image-family=cos-stable \
        --image-project=cos-cloud \
        --service-account=$SERVICE_ACCOUNT \
        --container-command="register" \
        --container-arg="--non-interactive" \
        --container-arg="--url \"https://gitlab.com\"" \
        --container-arg="--registration-token $REGISTRATION_TOKEN" \
        --container-arg="--description \"gitlab-docker-executor-vm\"" \
        --container-arg="--executor docker" \
        --container-arg="--docker-image alpine:latest" \
        --container-arg="--tag-list \"docker,gcp\"" \
        --container-arg="--run-untagged=\"true\"" \
        --container-arg="--locked=\"false\"" \
        --container-arg="--access-level=\"not_protected\""
    return $?
}

list() {
    gcloud compute instances list \
        --project=$PROJECT \
        --zones=$ZONE
    return $?
}

delete() {
    local list=$(list)
    echo -e "Machines that are running...\n${list}"

    echo "Enter instance to delete..."
    instance=$(read instance)
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
        if [[ "$run" == "create" && -z "$token" ]]; then
            echo -e "Must include required GitLab Registration Token.\n\

            ./create_container_vm.sh create \n\
                -z us-central1-a \n\
                -p prod-partner-a-176bffe6 \n\
                -s custom-sa@sample-project.iam.gserviceaccount.com \n\
                -r us-central1 \n\
                -t TOKEN"
        elif [[ "$run" == "create" && -n "$token" && "$token" != "" ]]; then
            echo -e "Running ${run}..." && $run
        else
            echo -e "Running ${run}..." && $run
        fi
    fi
fi
