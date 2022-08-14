#K8S_VERSION="1.23.5-00"
K8S_VERSION="1.21.3-00"
WORKINGDIR='/local/repository'
username=$(id -un)
HOME=/users/$(id -un)
usergid=$(id -ng)
KUBEHOME="${WORKINGDIR}/kube"

# Change login shell for
sudo chsh -s /bin/bash $username

# Redirect output to log file
exec >> ${WORKINGDIR}/deploy.log
exec 2>&1

sudo chown ${username}:${usergid} ${WORKINGDIR}/ -R
cd $WORKINGDIR

mkdir -p $KUBEHOME
export KUBECONFIG=$KUBEHOME/admin.conf
#echo "export KUBECONFIG=${KUBECONFIG}" > $HOME/.profile

# Add repositories
# Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update apt lists
sudo apt-get update

# Install pre-reqs
sudo apt-get -y install build-essential libffi-dev python python-dev python-pip automake autoconf libtool indent vim tmux xgrep jq #ctags

# pre-reqs for installing docker
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Disable swapoff
sudo swapoff -a

# Kubernetes
sudo apt-get -y install kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION kubernetes-cni golang-go

# Docker
sudo apt-get -y install docker-ce docker-ce-cli containerd.io
# Print Docker version
sudo docker version
# Change cgroup driver to systemd
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Kubernetes and Docker installed"