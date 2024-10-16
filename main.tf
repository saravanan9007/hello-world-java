provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "eks_vpc"{
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostname = true
    tags = {
        Name = "eks-vpc"
    }
}

resource "aws_subnet" "eks_subnet_a" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags{
        Name = "eks-subnet-a"
    }
}

resource "aws_subnet" "eks_subnet_b" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    tags{
        Name = "eks-subnet-b"
    }
}

resource "aws_eks_cluster" "eks_cluster" {
    name = "my-eks-cluster"
    role_arn = aws_iam_role.eks_role.arn

    vpc_config {
        subnet_ids = [
            aws_subnet.eks_subnet_a.id,
            aws_subnet.eks_subnet_b.id,
        ]
    }
    depends_on = [aws_iam_role_policy_attachment.eks_policy_attachment]
}

resource "aws_iam_role" "eks_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmasonEKSClusterPolicy"
    role  = aws_iam_role.eks_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = "my-eks-node-group"
    node_role_arn = aws_iam_role.eks_node_role.arn
    subnet_ids   = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]

    scaling_config {
        desired_size = 2
        max_size   = 3
        min_size   = 1
    }

    depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_iam_role" "eks_node_role" {
    name = "eks-node-role"

    assume_role_policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [{
            Action  = "sts:AssumeRole"
            Effect  = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role  = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role   = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role  = aws_iam_role.eks_node_role.name
}