
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  
}


//Creating KEY
resource "tls_private_key" "tls_key" {
   algorithm = "RSA"
}
//Generating Key-Value Pair
resource "aws_key_pair" "generated_dev_key" {
   key_name = "Task1DevKey1"
   public_key ="${tls_private_key.tls_key.public_key_openssh}"
   
 depends_on = [
      tls_private_key.tls_key
   ]
}
//Saving Private KEY PEM File
resource "local_file" "key-file" {
   content  = "${tls_private_key.tls_key.private_key_pem}"
   filename = "Task1DevKey1.pem"
   depends_on = [
      tls_private_key.tls_key,
      aws_key_pair.generated_dev_key
  ]
}

# NETWORKING #

#Creating own VPC
resource "aws_vpc" "devvpc" {
  cidr_block       = var.dev_cidr_block
  tags = {
    Name = "DevVpc"
  }
}

#creating public subnet for frontend 
resource "aws_subnet" "dev_public_subnet" {
  vpc_id     = aws_vpc.devvpc.id
  cidr_block = var.dev_public_subnet_cidr_block
  availability_zone = var.dev_public_az
  tags = {
    Name = "dev_public_subnet"
  }
}



#creating private subnet for backend app server
resource "aws_subnet" "dev_app_private_subnet" {
    vpc_id = aws_vpc.devvpc.id
    cidr_block = var.dev_private_backend_subnet_cidr_block
    availability_zone = var.dev_private_az
    tags = {
      Name = "dev_app_private_subnet"
  }
}
#creating private subnet for backend RDS
resource "aws_subnet" "dev_rds_private_subnet_1" {
    vpc_id = aws_vpc.devvpc.id
    cidr_block = var.dev_private_rds_subnet_cidr_block_1
    availability_zone = var.dev_rds_az_1
    tags = {
      Name = "dev_rds_private_subnet_1"
  }
}

resource "aws_subnet" "dev_rds_private_subnet_2" {
    vpc_id = aws_vpc.devvpc.id
    cidr_block = var.dev_private_rds_subnet_cidr_block_2
    availability_zone = var.dev_rds_az_2
    tags = {
      Name = "dev_rds_private_subnet_2"
  }
}

#creating internet gateway for our vpc
resource "aws_internet_gateway" "dev_internet_gateway" {
  vpc_id = aws_vpc.devvpc.id
  tags = {
    Name = "dev_internet_gateway"
  }
}

#creating routing table for the internet gateway
resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.devvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_internet_gateway.id
  }
  tags = {
    Name = "dev_route_table"
  }
}


#creating an association between route table & subnet
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_route_table.id
}


#creating security group for frontend 
resource "aws_security_group" "sg_dev_frontend" {
  name        = "my_frontend_dev_security"
  description = "allow ssh, http traffic"
  vpc_id      =  aws_vpc.devvpc.id


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg_dev_frontend"
  }
} 


#creating security group for backend instance
resource "aws_security_group" "sg_dev_app_backend" {
  name        = "dev_backend_app_security"
  description = "allow ssh, backend traffic"
  vpc_id      =  aws_vpc.devvpc.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "Backend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg_dev_app_backend"
  }
} 

#creating security group for backend RDS instance
resource "aws_security_group" "mydb1" {
  name = "mydb1"

  description = "RDS postgres servers (terraform-managed)"
  vpc_id = aws_vpc.devvpc.id

  # Only postgres in
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "mydb1_rds_subnet_group" {
  name     = "mydb1_rds_subnet_group"

  tags = { Name = "DB RDS" }
  subnet_ids = [aws_subnet.dev_rds_private_subnet_1.id,aws_subnet.dev_rds_private_subnet_2.id]
}

#launching EC2 instance in public subnet
resource "aws_instance" "dev_frontend" {
  ami           = "ami-06a0b4e3b7eb7a300"
  instance_type = "t2.micro"
   key_name = "${aws_key_pair.generated_dev_key.key_name}"
  associate_public_ip_address = true
  subnet_id = aws_subnet.dev_public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_dev_frontend.id]
  availability_zone = "ap-south-1a"
  user_data = file("install_apache.sh")
  tags = {
    Name = "Dev_frontend"
  }
}

#launching back end EC2 instance in private subnet
resource "aws_instance" "dev_backend" {
  ami           = "ami-06a0b4e3b7eb7a300"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.generated_dev_key.key_name}"
  subnet_id = aws_subnet.dev_app_private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_dev_app_backend.id]
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Dev_backend"
  }
}

#launching RDS instance in private subnet
resource "aws_db_instance" "mydb1" {
  allocated_storage        = 20 # gigabytes
  backup_retention_period  = 7   # in days
  db_subnet_group_name     = aws_db_subnet_group.mydb1_rds_subnet_group.id
  engine                   = "postgres"
#  engine_version           = "12.5"
  identifier               = "mydb1"
  instance_class           = "db.t2.micro"
  multi_az                 = false
  username                 = "mydb1"
  name                     = "mydb1"
  password                 = "mypassword"
  port                     = 5432
  publicly_accessible      = false
  storage_encrypted        = false 
  storage_type             = "gp2"
  vpc_security_group_ids   = [aws_security_group.mydb1.id]
}

// Create S3 Bucket
resource "aws_s3_bucket" "task1bucketbindudevbucket00" {
  bucket = "task1bucketbindudevbucket00"
  acl    = "private"
  tags = {
  Name = "task1bucketbindudevbucket00"
 }
}
// Allow Public Access
resource "aws_s3_bucket_public_access_block" "S3PublicAccess" {
  bucket = "${aws_s3_bucket.task1bucketbindudevbucket00.id}"
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}
locals {
  asg_names = [
    "Dev-FrontEnd1",
    "Dev-BackEnd1",
  ]
}

locals {
  body = [for asg_name in local.asg_names :
        {
            type: "metric",
            x: 0,
            y: 0,
            width: 9,
            height: 6,
            properties: {
                view: "bar",
                stacked: false,
                metrics: [
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", asg_name ],
                    [ ".", "GroupMaxSize", ".", "." ],
                    [ ".", "GroupTotalCapacity", ".", "." ],
                    [ ".", "GroupTotalInstances", ".", "." ],
                    [ ".", "GroupInServiceInstances", ".", "." ]
                ]
                region: var.region,
                title: asg_name
            }
        }
        ]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Dev-dashboard"

  dashboard_body = jsonencode({ 
  widgets: concat(local.body, [{
      type: "text",
      x: 0,
      y: 7,
      width: 3,
      height: 3,
      properties: {
        markdown: "New Dashboard coming soon.."
      }
    }])
  })
}
