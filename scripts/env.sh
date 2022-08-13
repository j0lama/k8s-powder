K8S_VERSION="1.23.5-00"
WORKINGDIR='/local/repository'
username=$(id -un)
HOME=/users/$(id -un)
usergid=$(id -ng)
KUBEHOME="${WORKINGDIR}/kube"

# Redirect output to log file
exec >> ${WORKINGDIR}/deploy.log
exec 2>&1

sudo chown ${username}:${usergid} ${WORKINGDIR}/ -R
cd $WORKINGDIR

mkdir -p $KUBEHOME
export KUBECONFIG=$KUBEHOME/admin.conf
# make SSH shells play nice
sudo chsh -s /bin/bash $username
echo "export KUBECONFIG=${KUBECONFIG}" > $HOME/.profile