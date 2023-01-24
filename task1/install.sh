#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Import bash library (incase we use a bash presentation)
. "${DIR}/nav.sh"

# INSTALL Cert Manager plugin
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
kubectl create namespace demo
kubectl apply -f ${DIR}/cf-secret.yaml
kubectl apply -f ${DIR}/cluster-issuer.yaml
kubectl apply -f ${DIR}/certificate.yml
# INSTALL CSI plugin

export EBS_CSI_POLICY_NAME="Amazon_EBS_CSI_Driver"
export AWS_REGION=ap-southeast-1

mkdir -p ${DIR}/environment/ebs_statefulset
cd ${DIR}/environment/ebs_statefulset

# download the IAM policy document
curl -sSL -o ebs-csi-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json

# Create the IAM policy
aws iam wait policy-exists --policy-arn arn:aws:iam::292126636041:policy/Amazon_EBS_CSI_Driver || \
aws iam create-policy \
  --region ${AWS_REGION} \
  --policy-name ${EBS_CSI_POLICY_NAME} \
  --policy-document file://${DIR}/environment/ebs_statefulset/ebs-csi-policy.json > /dev/null

sleep 10
# export the policy ARN as a variable
export EBS_CSI_POLICY_ARN=$(aws --region ${AWS_REGION} iam list-policies --query 'Policies[?PolicyName==`'${EBS_CSI_POLICY_NAME}'`].Arn' --output text)

# Create an IAM OIDC provider for your cluster
eksctl utils associate-iam-oidc-provider \
  --region=${AWS_REGION} \
  --cluster=eks-demo \
  --approve

# Create a service account
eksctl create iamserviceaccount \
  --cluster eks-demo \
  --name ebs-csi-controller-irsa \
  --namespace kube-system \
  --attach-policy-arn ${EBS_CSI_POLICY_ARN} \
  --override-existing-serviceaccounts \
  --approve

# Create a service account
eksctl create iamserviceaccount \
  --cluster eks-demo \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --attach-policy-arn ${EBS_CSI_POLICY_ARN} \
  --override-existing-serviceaccounts \
  --approve
  
# add the aws-ebs-csi-driver as a helm repo
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver

helm upgrade --install aws-ebs-csi-driver \
  --version=2.16.0 \
  --namespace kube-system \
  --set serviceAccount.controller.create=false \
  --set serviceAccount.snapshot.create=false \
  --set enableVolumeScheduling=true \
  --set enableVolumeResizing=true \
  --set enableVolumeSnapshot=true \
  --set serviceAccount.snapshot.name=ebs-csi-controller-irsa \
  --set serviceAccount.controller.name=ebs-csi-controller-irsa \
  aws-ebs-csi-driver/aws-ebs-csi-driver

cat << EoF > ${DIR}/environment/ebs_statefulset/storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fullnode-storage-class
provisioner: ebs.csi.aws.com # Amazon EBS CSI driver
parameters:
  type: gp2
  encrypted: 'true' # EBS volumes will always be encrypted by default
volumeBindingMode: WaitForFirstConsumer # EBS volumes are AZ specific
reclaimPolicy: Retain
allowVolumeExpansion: true
mountOptions:
- debug
EoF

kubectl create -f ${DIR}/environment/ebs_statefulset/storageclass.yaml

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress --namespace nginx-ingress ingress-nginx/ingress-nginx


kubectl create -f ${DIR}/sts.yml -f ${DIR}/svc.yml -f ${DIR}/ingress.yml
