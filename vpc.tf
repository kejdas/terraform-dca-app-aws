resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16" # default gateway (main address)

    tags = {
        Name = "dca-app-vpc"
    }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id # this links the subnet to our VPC
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "dca-app-public-subnet"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "dca-app-gateway"
    }
}


resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id 

    route {
        cidr_block = "0.0.0.0/0" # this means "all ipv4 traffic"
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "dca-app-public-route-table"
    }
}

resource "aws_route_table_association" "route_association" {
    subnet_id = aws_subnet.public.id 
    route_table_id = aws_route_table.public_rt.id

}
resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id # this links the subnet to our VPC
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-central-1b"

    tags = {
    Name = "dca-app-public-subnet-2"
  }
}

resource "aws_route_table_association" "route_association_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}
  
