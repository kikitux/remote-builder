#!/bin/bash -x

# Always delete instance after attempting build
function cleanup {
    gcloud compute instances delete ${INSTANCE_NAME} --quiet
}

# Configurable parameters
[ -z "${COMMAND}" ] && echo "Need to set COMMAND" && exit 1;

USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace/}
INSTANCE_NAME=${INSTANCE_NAME:-builder-$(cat /proc/sys/kernel/random/uuid)-${RANDOM}}
ZONE=${ZONE:-us-central1-f}
INSTANCE_ARGS=${INSTANCE_ARGS:---preemptible}
KEYNAME=builder-key-${RANDOM}
SSHKEYS=ssh-keys-${RANDOM}

# create ssh KEYNAME
[ -f ${KEYNAME} ] || {
  ssh-keygen -t rsa -N "" -f ${KEYNAME} -C ${USERNAME}
  chmod 400 ${KEYNAME}*

  cat > ${SSHKEYS} <<EOF
${USERNAME}:$(cat ${KEYNAME}.pub)
EOF
}

set -e
gcloud config set compute/zone ${ZONE}

time gcloud compute instances create \
       ${INSTANCE_ARGS} ${INSTANCE_NAME} \
       --metadata block-project-ssh-keys=TRUE \
       --metadata-from-file ssh-keys=${SSHKEYS}

retry=5
i=0
set +e
while [ ${i} -lt ${retry} ]; do
       gcloud compute ssh --ssh-key-file=${KEYNAME} ${USERNAME}@${INSTANCE_NAME} -- "echo instance now up"
       [ $? -eq 0 ] && break
       let i++
       sleep 4
done


unset retry
unset i


trap cleanup EXIT
set -e

time gcloud compute scp --compress --recurse \
       $(pwd) ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE} \
       --ssh-key-file=${KEYNAME}

time gcloud compute ssh --ssh-key-file=${KEYNAME} \
       ${USERNAME}@${INSTANCE_NAME} -- ${COMMAND}

time gcloud compute scp --compress --recurse \
       ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE}* $(pwd) \
       --ssh-key-file=${KEYNAME}
