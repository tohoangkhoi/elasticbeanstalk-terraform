resource "aws_db_subnet_group" "db_subnet_group" {
  name       = local.db_subnet_group_name
  subnet_ids = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = local.db_subnet_group_name
  }
}

resource "aws_rds_cluster" "db_cluster" {
  cluster_identifier           = local.db_cluster_name
  engine                       = "aurora-postgresql"
  master_username              = local.db_username
  master_password              = local.db_password
  vpc_security_group_ids       = [aws_security_group.rds_security_group.id]
  storage_encrypted            = true
  kms_key_id                   = local.kms_key_id
  backup_retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sat:03:00-sat:05:00"
  db_subnet_group_name         = aws_db_subnet_group.db_subnet_group.name
  database_name                = local.db_name
  skip_final_snapshot          = true
}


resource "aws_rds_cluster_instance" "db_instance" {
  count                = 1
  identifier           = "${local.db_cluster_name}-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.db_cluster.id
  instance_class       = "db.r5.large"
  engine               = "aurora-postgresql"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
}