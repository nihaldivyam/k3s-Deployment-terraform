provider "aws" {
  region = "ap-south-1"
}
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.deployer-public-key
}
resource "aws_instance" "master" {
  ami           = var.ami_id
  instance_type = var.worker_instance_type
  key_name = aws_key_pair.deployer.key_name
  user_data = templatefile("data/main-server.tmpl", {


  })

}

resource "null_resource" "echo_master_ip" {
  provisioner "local-exec" {
    command = "sleep 210s && echo ${aws_instance.master.public_ip}"
  }
}
resource "null_resource" "copy-kubeconfig" {
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${aws_instance.master.public_ip}:/home/ec2-user/k3s.yaml ./k3s-kubeconfig.yaml"
  }
  depends_on = [null_resource.echo_master_ip]
}

resource "null_resource" "copy-nodetoken" {
  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${aws_instance.master.public_ip}:/home/ec2-user/node-token ./node-token"
  }
  depends_on = [null_resource.echo_master_ip]
}

### Install worker node

resource "aws_instance" "worker-node" {
  ami                  = var.ami_id
  instance_type        = var.worker_instance_type
  key_name             = aws_key_pair.deployer.key_name


  user_data = templatefile("data/agent-server.tmpl", {
    master_ip       = aws_instance.master.public_ip,
    master_local_ip = aws_instance.master.private_ip,
    node_token      = var.k3s_token,
    cluster_name    = var.cluster_name,
    
  })

}


output "Master_public_ip" {
  value = aws_instance.master.public_ip
}