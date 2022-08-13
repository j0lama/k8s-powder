K8S_VERSION="1.23.5-00"
SCRIPTDIR=$(dirname "$0")
WORKINGDIR='/local/repository'
username=$(id -un)
HOME=/users/$(id -un)
usergid=$(id -ng)
KUBEHOME="${WORKINGDIR}/kube"