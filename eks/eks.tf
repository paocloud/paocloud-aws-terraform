variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}
variable "account_id" {}

provider "aws" {
   region = var.region
   access_key = var.aws_access_key
   secret_key = var.aws_secret_key
}

resource "aws_iam_policy" "paocloud-eks-autoscale-policy" {
  name        = "AmazonEKSClusterAutoscalerPolicy"
  description = "AmazonEKSClusterAutoscalerPolicy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "paocloud-eks-autoscale-role" {
  name = "paocloud-eks-autoscale-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.ap-southeast-1.amazonaws.com/id/0728ACFAE4B90071B2BE39439C8C2E75:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      },
      "Principal": {
        "Federated": "arn:aws:iam::xxxxx:oidc-provider/oidc.eks.ap-southeast-1.amazonaws.com/id/0728ACFAE4B90071B2BE39439C8C2E75"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
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

resource "aws_iam_role_policy_attachment" "paocloud-eks-autoscale-policy-attacth" {
  policy_arn = aws_iam_policy.paocloud-eks-autoscale-policy.arn
  role       = aws_iam_role.paocloud-eks-autoscale-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.paocloud-eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.paocloud-eks-cluster.name
}

resource "aws_security_group" "paocloud-eks" {
  name        = "paocloud-eks-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "vpc-0ae56aba8f8ded39d"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    //vpc block
    cidr_blocks = ["172.31.0.0/16"]
  }

  tags = {
    Name = "paocloud-eks-cluster"
    Project = "paocloud"
  }
}

resource "aws_security_group_rule" "paocloud-eks-ingress-workstation-https" {
  //vpc block
  cidr_blocks       = ["172.31.0.0/16"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.paocloud-eks.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "paocloud-eks" {
  name     = "paocloud-eks"
  version = 1.19
  role_arn = aws_iam_role.paocloud-eks-cluster.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access =  false
    security_group_ids = [aws_security_group.paocloud-eks.id]
    subnet_ids = ["subnet-xxxx", "subnet-yyyy", "subnet-zzzz"]
  }

  tags = {
    Name = "paocloud-eks"
    Project = "paocloud"
  }
}

resource "aws_iam_role" "paocloud-eks-nodes" {
  name = "paocloud-eks-nodes-group"

  //var.OIDC_ARN = aws_iam_openid_connect_provider.paocloud-eks.arn 
  //var.OIDC_URL = replace(aws_iam_openid_connect_provider.paocloud-eks.url, "https://", "")

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

resource "aws_launch_template" "paocloud-ec2-eks-launch-template" {
  name = "paocloud-ec2-eks-launch-template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 50
    }
  }

  image_id = "ami-063e2a44db52cc23d"

  instance_type = "t3a.medium"

  key_name = "paocloud-key"

  user_data = filebase64("user_data.sh")

  //ec2 node security group
  vpc_security_group_ids = ["sg-xxxxx"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "paocloud-eks-node"
      Project = "paocloud"
    }
  }

}

resource "aws_eks_node_group" "paocloud-eks-node" {
  cluster_name    = aws_eks_cluster.paocloud-eks.name
  node_group_name = "paocloud-node-group-1"
  node_role_arn   = aws_iam_role.paocloud-eks-nodes.arn
  subnet_ids = ["subnet-0a34ba3f3f1045ee0", "subnet-027ce2a66d7cdc04b", "subnet-0b801d64e9bc358cc"]

  //launch_template = "paocloud-ec2-launch-template"
  
  launch_template {
    name = aws_launch_template.paocloud-ec2-eks-launch-template.name
    version = 1
  }

  //instance_types = ["t3a.medium"]
  
  //disk_size = "50"

  //remote_access {
    //ec2_ssh_key = "paocloud-key"
  //}

  scaling_config {
    desired_size = 3
    max_size     = 8
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
  tags = {
    "k8s.io/cluster-autoscaler/paocloud-eks" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "Project" = "paocloud"
  }
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.paocloud-eks.endpoint
}

output "eks_cluster_certificat_authority" {
  value = aws_eks_cluster.paocloud-eks.certificate_authority
}
