#!/bin/bash
set -ex

# NOTE: In order to use driver overlay mount in rootless mode,
# you will need to run this script in a `buildah unshare` session
# buildah unshare ./ee_buildah_aap2_22.sh

# podman login registry.redhat.io
# Username: {REGISTRY-SERVICE-ACCOUNT-USERNAME}
# Password: {REGISTRY-SERVICE-ACCOUNT-PASSWORD}

# Automation Hub API token
# Go to https://cloud.redhat.com/ansible/automation-hub/token/
# Click Load token from the version dropdown to copy your API token.
API_TOKEN=

BASEIMAGEOWNER=ansible-automation-platform-22
#full EE
#BASEIMAGENAME=ee-supported-rhel8
#BIVERSION=1.0.0-229
#minimal EE
BASEIMAGENAME=ee-minimal-rhel8
BIVERSION=1.0.0-373
#automated-satellite-ee
IMAGE=ee-automated-satellite-aap2
VERSION=1.0.3
START_DIR=$(pwd)
TMP_WRKDIR=$(mktemp -d /tmp/XXXXXXXX)
ctr=$(buildah from registry.redhat.io/$BASEIMAGEOWNER/$BASEIMAGENAME:$BIVERSION)
scratchmnt=$(buildah mount ${ctr})
buildah run $ctr /bin/sh -c 'python3 -m pip install boto==2.49.0'
buildah run $ctr /bin/sh -c 'python3 -m pip install boto3==1.17.56'
buildah run $ctr /bin/sh -c 'python3 -m pip install apypie==0.4.0'
buildah run $ctr /bin/sh -c 'python3 -m pip install psycopg2-binary==2.9.6'
#buildah run $ctr /bin/sh -c 'rm /usr/libexec/platform-python3.6'
#buildah run $ctr /bin/sh -c 'ln -s /usr/bin/python3 /usr/libexec/platform-python3.6'
cd $TMP_WRKDIR
git clone https://github.com/redhat-partner-tech/automated-satellite.git
cd automated-satellite
git checkout ee-build-source-aap2-22

sed -i "s/AABBccddeeff112233gghh/$API_TOKEN/g" ansible.cfg
buildah copy $ctr 'ansible.cfg' '/etc/ansible/ansible.cfg'

buildah copy $ctr 'collections/requirements.yml' '/tmp/requirements.yml'
buildah run $ctr /bin/sh -c 'ansible-galaxy collection install -r /tmp/requirements.yml -p /usr/share/ansible/collections'
buildah run $ctr /bin/sh -c 'rm /tmp/requirements.yml'
buildah run $ctr /bin/sh -c 'ansible-config init --disabled > /etc/ansible/ansible.cfg'

buildah copy $ctr 'roles/content_views' '/usr/share/ansible/roles/content_views'
buildah copy $ctr 'roles/ec2_node_tools' '/usr/share/ansible/roles/ec2_node_tools'
buildah copy $ctr 'roles/rhsm_register' '/usr/share/ansible/roles/rhsm_register'
buildah copy $ctr 'roles/scap_client' '/usr/share/ansible/roles/scap_client'

#buildah config --label name=${IMAGE} $ctr
cd $START_DIR
rm -rf $TMP_WRKDIR
buildah commit $ctr ${IMAGE}:${VERSION}
podman tag ${IMAGE}:${VERSION} ${IMAGE}:latest
buildah umount $ctr
buildah rm $ctr

# podman login quay.io
# podman push ${IMAGE}:${VERSION} quay.io/s4v0/${IMAGE}:${VERSION}
