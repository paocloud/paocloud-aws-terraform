provider "aws" {
   region = "ap-southeast-1"
   access_key = "my-access-key"
   secret_key = "my-secret-key"
}

resource "aws_iam_role" "paocloud-eks-cluster" {
  name = "paocloud-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.paocloud-eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.paocloud-eks-cluster.name
}

resource "aws_eks_cluster" "paocloud-eks" {
  name     = "paocloud-eks"
  role_arn = aws_iam_role.paocloud-eks-cluster.arn

  vpc_config {
    subnet_ids = ["subnet-aaaa", "subnet-bbbb"]
  }

  tags = {
    Name = "paocloud-eks"
  }
}

resource "aws_iam_role" "paocloud-eks-nodes" {
  name = "paocloud-eks-nodes-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.paocloud-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.paocloud-eks-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.paocloud-eks-nodes.name
}

resource "aws_eks_node_group" "paocloud-eks-node" {
  cluster_name    = aws_eks_cluster.paocloud-eks.name
  node_group_name = "paocloud-node-group"
  node_role_arn   = aws_iam_role.paocloud-eks-nodes.arn
  subnet_ids      = ["subnet-aaaa", "subnet-bbbb"]

  instance_types = ["t3.medium"]
  
  disk_size = "40"

  remote_access {
    ec2_ssh_key = "paomini"
  }

  scaling_config {
    desired_size = 4
    max_size     = 10
    min_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    "k8s.io/cluster-autoscaler/paocloud-eks" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
  }
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.paocloud-eks.endpoint
}

output "eks_cluster_certificat_authority" {
  value = aws_eks_cluster.paocloud-eks.certificate_authority
}
