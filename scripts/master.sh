#!/bin/bash
#set -u
#set -x

# Ensure this script is run once
if [ -f /local/repository/master-ready ]; then
    exit 0
fi

# Set env variables & install K8s, Docker and dependencies
source /local/repository/scripts/common.sh

sudo kubeadm init --config=config/kubeadm-config.yaml

# result will be like:  kubeadm join 155.98.36.111:6443 --token i0peso.pzk3vriw1iz06ruj --discovery-token-ca-cert-hash sha256:19c5fdee6189106f9cb5b622872fe4ac378f275a9d2d2b6de936848215847b98

# allow sN to log in with shared key
# see http://docs.powderwireless.net/advanced-topics.html
geni-get key > ${HOME}/.ssh/id_rsa
chmod 600 ${HOME}/.ssh/id_rsa
ssh-keygen -y -f ${HOME}/.ssh/id_rsa > ${HOME}/.ssh/id_rsa.pub
grep -q -f ${HOME}/.ssh/id_rsa.pub ${HOME}/.ssh/authorized_keys || cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys

# https://github.com/kubernetes/kubernetes/issues/44665
sudo cp /etc/kubernetes/admin.conf $KUBEHOME/
sudo chown ${username}:${usergid} $KUBEHOME/admin.conf

# Install Flannel. See https://github.com/coreos/flannel
sudo kubectl apply -f /local/repository/config/flannel-network-conf.yaml

# use this to enable autocomplete
source <(kubectl completion bash)

# Allow scheduling of pods on master
kubectl taint node $(kubectl get nodes -o json | jq -r .items[0].metadata.name) node-role.kubernetes.io/master:NoSchedule-

# install static cni plugin
sudo go get -u github.com/containernetworking/plugins/plugins/ipam/static
sudo go build -o /opt/cni/bin/static github.com/containernetworking/plugins/plugins/ipam/static

# install helm
echo "Installing Helm"
wget https://get.helm.sh/helm-v3.1.0-linux-amd64.tar.gz
tar xf helm-v3.1.0-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/helm

source <(helm completion bash)

# Wait till the slave nodes get joined and update the kubelet daemon successfully
# number of slaves + 1 master
node_cnt=$(($(/local/repository/scripts/geni-get-param.sh computeNodeCount) + 1))
# 1 node per line - header line
joined_cnt=$(( `kubectl get nodes | wc -l` - 1 ))
while [ $node_cnt -ne $joined_cnt ]
do 
    joined_cnt=$(( `kubectl get nodes | wc -l` - 1 ))
    echo "Total nodes: $node_cnt Joined: ${joined_cnt}"
    sleep 1
done
echo "All nodes joined"

#Deploy metrics server
sudo kubectl create -f config/metrics-server.yaml

# to know how much time it takes to instantiate everything.
echo "Setup DONE!"
date

touch /local/repository/master-ready