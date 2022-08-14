K8S_VERSION="1.23.5-00"
#K8S_VERSION="1.21.3-00"
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

##############
# Containerd #
##############
# Configure required modules
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
# Configure required sysctl to persist across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# Apply sysctl parameters without reboot to current running enviroment
sudo sysctl --system
# Install containerd
sudo apt-get install -y containerd
# Create configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
# Set containerd cgroup driver to systemd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
# Restart containerd daemon
sudo systemctl restart containerd

##############
# Kubernetes #
##############
sudo apt-get -y install kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION kubernetes-cni golang-go

echo "Kubernetes and Docker installed"