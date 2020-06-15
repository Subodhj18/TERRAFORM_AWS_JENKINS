provider "aws"{
    region = "ap-south-1"
    profile = "subodh"
}
//CREATING THE SECURITY GROUP

resource "aws_security_group" "secgroup" {
  name        = "secgroup"
  description = "Allow Http and ssh"
  vpc_id      = "vpc-bb8895d3"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "secgroup"  
}
}
resource "aws_instance" "terraform1_OS" {
    ami                 = "ami-0447a12f28fddb066"
    instance_type        = "t2.micro"
    key_name            = "cckey"
    availability_zone    = "ap-south-1a"
    security_groups        = [ "secgroup" ]
    
    connection{
        type            = "ssh"
        user            = "ec2-user"
        private_key        = file("C:/Users/hp/Contacts/Downloads/cckey.pem")
        host            = aws_instance.terraform1_OS.public_ip
    }
    
    provisioner "remote-exec"{
        inline = [
            "sudo yum install httpd  php git -y",
			"setenforce 0",
            "sudo systemctl start httpd",
            "sudo systemctl enable httpd",
        ]
    }

    tags = {
        Name = "terraform1_OS"  
    }
  
}

//CREATING THE EBS VOLUME

resource "aws_ebs_volume" "t1_storage" {
    availability_zone    = aws_instance.terraform1_OS.availability_zone
    size                 = 2
    tags = {
        Name = "t1_storage"
    }
}
//ATTACHING THE EBS VOLUME

resource "aws_volume_attachment" "ebs_attach" {
    device_name            = "/dev/sdh"
    volume_id              = "${ aws_ebs_volume.t1_storage.id }"
    instance_id            = "${ aws_instance.terraform1_OS.id }"
    force_detach           = true
}
    
	
resource "null_resource" "nullremote1"{
    depends_on = [
        aws_volume_attachment.ebs_attach,
    ]
    
    connection{
        private_key        = file("C:/Users/hp/Contacts/Downloads/cckey.pem")
        type               = "ssh"
        user               = "ec2-user"
        host               = aws_instance.terraform1_OS.public_ip
    }
    
    provisioner "remote-exec"{
        inline = [
            "sudo mkfs.ext4 /dev/xvdh",
            "sudo mount /dev/xvdh /var/www/html",
			"sudo rm -rf /var/www/html/*",
			"git clone https://github.com/Subodhj18/TERRAFORM_AWS_JENKINS.git /var/www/html/"
			
        ]
    }
}	