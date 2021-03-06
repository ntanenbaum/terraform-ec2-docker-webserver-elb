# Bastion Host ec2 Instance
resource "aws_instance" "ntbastioninstance" {
  depends_on = [aws_vpc.ntvpc, aws_subnet.ntvpc_private_sn]

  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.ntvpc_bastserver_sg.id]
  subnet_id = aws_subnet.ntvpc_public_sn.id
  disable_api_termination = false
  monitoring = false

  tags = {
      Name = "nt-bastion-host"
  }

  provisioner "file" {
    source      = "/tmp/terraform_iac/ec2Key.pem"
    destination = "/home/ec2-user/ec2Key.pem"

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.private_key.private_key_pem
    host     = aws_instance.ntbastioninstance.public_ip
    }
  }
 
  user_data = <<EOF
            #!/bin/bash
            chmod 600 /home/ec2-user/ec2Key.pem
  EOF
}

# Elastic ip - mask failure of instance reserved address
resource "aws_eip" "ntvpc_public_sn_ng_elastic_ip" {
  vpc  = true

  tags = {
    Name = "nt-elastic-ip"
  }
}

# Webserver ec2 Instance
resource "aws_instance" "ntwebsvr" {
  depends_on = [aws_vpc.ntvpc, aws_security_group.ntvpc_webserver_sg]

  count = 2
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.ntvpc_webserver_sg.id]
  subnet_id = aws_subnet.ntvpc_private_sn.id
  disable_api_termination = false
  associate_public_ip_address = false
  monitoring = false
  user_data = file("scripts/userdataweb.sh")

  tags = {
      Name = "nt-webserver0${count.index+1}"
  }
}

