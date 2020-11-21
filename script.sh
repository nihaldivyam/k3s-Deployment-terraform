#!/bin/bash

sudo yum update -y

sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo docker run -d -p 5000:5000 --restart=always -e REGISTRY_STORAGE_DELETE_ENABLED=true --name registry registry:2

export INSTANCE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
export NODE_PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

cat << EOF >> /etc/docker/daemon.json
{"insecure-registries": ["$INSTANCE_IP:5000"]}
EOF

sudo service docker restart

cat << EOF >> /home/ec2-user/registries.yaml
mirrors:
  docker.io:
    endpoint:
      - "https://registry-1.docker.io"
  $INSTANCE_IP:5000:
    endpoint:
      - "http://$INSTANCE_IP:5000"
EOF

export INSTALL_K3S_VERSION=v1.18.4+k3s1
export K3S_NODE_NAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
export PROVIDER_ID=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

export INSTALL_K3S_EXEC=" \
    --cluster-init \
    --tls-san $NODE_PUBLIC_IP \
    --kubelet-arg provider-id=$PROVIDER_ID \
    --kubelet-arg allowed-unsafe-sysctls=kernel.msg*,net.core.somaxconn "

curl -sfL https://get.k3s.io | sh -


echo -n $(sudo cat /etc/rancher/k3s/k3s.yaml) > /home/ec2-user/k3s.yaml
echo -n $(sudo cat /var/lib/rancher/k3s/server/node-token) > /home/ec2-user/node-token

kubectl apply -f https://raw.githubusercontent.com/transhapHigsn/cloud-provider-aws/higsn-dev/manifests/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/transhapHigsn/cloud-provider-aws/higsn-dev/manifests/aws-cloud-controller-manager-daemonset.yaml

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


