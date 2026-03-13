resource "aws_security_group" "bastion_sg" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 00
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-bastion-sg"
  }
}

resource "aws_security_group_rule" "node_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description              = "Allow inbound SSH from Bastion host"
}

resource "aws_iam_role" "bastion_role" {
  name = "${var.cluster_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bastion_eks_policy" {
  name = "${var.cluster_name}-bastion-eks-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.cluster_name}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami != "" ? var.bastion_ami : data.aws_ami.amazon_linux_2.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  key_name                    = var.bastion_key_name != "" ? var.bastion_key_name : null

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install dependencies
    apt update -y
    apt install -y unzip curl

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  EOF

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}
