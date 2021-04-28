#!/bin/bash

################# AWS EKS USER DATA CONFIG ################# 

#### Update OS ####
sudo yum -y update

#### Timezone Config ####
sudo timedatectl set-timezone Asia/Bangkok

#### Auto Cleanup Docker Container Images ####
#### Ref : https://aws.amazon.com/premiumsupport/knowledge-center/eks-worker-nodes-image-cache/ ####

set -o xtrace

# Inject imageGCHighThresholdPercent value unless it has already been set.
if ! grep -q imageGCHighThresholdPercent /etc/kubernetes/kubelet/kubelet-config.json; 
then 
    sed -i '/"apiVersion*/a \ \ "imageGCHighThresholdPercent": 70,' /etc/kubernetes/kubelet/kubelet-config.json
fi

# Inject imageGCLowThresholdPercent value unless it has already been set.
if ! grep -q imageGCLowThresholdPercent /etc/kubernetes/kubelet/kubelet-config.json; 
then 
    sed -i '/"imageGCHigh*/a \ \ "imageGCLowThresholdPercent": 50,' /etc/kubernetes/kubelet/kubelet-config.json
fi

/etc/eks/bootstrap.sh paocloud-eks

#### Hostname Config ####
sudo hostnamectl set-hostname paocloud-eks-node
