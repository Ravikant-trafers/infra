provider "aws" {
  region = "${var.region}"
}

module "db_stage" {
  source         = "./modules/db"
  environment    = "stage"
  vpc_id         = "${data.terraform_remote_state.vpc-us-west-2.vpc_id}"
  identifier     = "developer-portal"
  instance_class = "db.t2.large"
  db_name        = "developer_portal"
  db_user        = "${lookup(var.rds, "user.stage")}"
  db_password    = "${lookup(var.rds, "password.stage")}"
}

module "bucket_stage" {
  source              = "./modules/bucket"
  environment         = "stage"
  create_user         = true
  bucket_name         = "developer-portal"
  eks_worker_role_arn = "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_iam_role_arn}"
}

module "efs_stage" {
  source      = "./modules/storage"
  environment = "stage"
  subnets     = "${data.terraform_remote_state.vpc-us-west-2.private_subnets}"

  nodes_security_group = [
    "${data.terraform_remote_state.eks-us-west-2.developer_portal_worker_security_group_id}",
    "${join(",", data.terraform_remote_state.kops-us-west-2.node_security_group_ids)}",
  ]
}

module "cdn_stage" {
  source          = "./modules/cdn"
  environment     = "stage"
  cdn_aliases     = ["developer-portal-stage.mdn.mozit.cloud"]
  origin_bucket   = "${module.bucket_stage.bucket_id}"
  certificate_arn = "arn:aws:acm:us-east-1:178589013767:certificate/26d329f6-aa7d-4999-af62-de573772585b"
}
