data "aws_vpc" "cluster_vpc" {
    count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
    id = var.aws_kubernetes_cluster_vpc_id
}

data "aws_vpc" "remote_vpc" {
    count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
    id = var.aws_remote_peering_vpc_id
}

data "aws_route_tables" "cluster_route_tables" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
  vpc_id = var.aws_kubernetes_cluster_vpc_id
}

data "aws_route_tables" "remote_route_tables" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
  vpc_id = var.aws_remote_peering_vpc_id
}

resource "aws_vpc_peering_connection" "peering_connection" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
  vpc_id        = var.aws_kubernetes_cluster_vpc_id
  peer_vpc_id   = var.aws_remote_peering_vpc_id
}

resource "aws_vpc_peering_connection_accepter" "remote_peering_accepter" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection[0].id
  auto_accept               = true
}

resource "aws_route" "remote_to_cluster" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? length(data.aws_route_tables.remote_route_tables[0].ids) : 0
  route_table_id            = tolist(data.aws_route_tables.remote_route_tables[0].ids)[count.index]
  destination_cidr_block    = data.aws_vpc.cluster_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection[0].id
}

resource "aws_route" "cluster_to_remote" {
  count = (var.cloud == "aws") && (var.aws_remote_peering_vpc_id != "") ? length(data.aws_route_tables.cluster_route_tables[0].ids) : 0
  route_table_id            = tolist(data.aws_route_tables.cluster_route_tables[0].ids)[count.index]
  destination_cidr_block    = data.aws_vpc.remote_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection[0].id
}
