module "networking" {
  source = "../../modules/networking"

  project_name      = var.project_name
  availability_zone = var.availability_zone
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = "devsecops-bankapp"
}


module "ec2_app" {
  source = "../../modules/ec2-app"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  subnet_id         = module.networking.public_subnet_id
  key_pair_name     = var.key_pair_name
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

module "ec2_ollama" {
  source = "../../modules/ec2-ollama"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  subnet_id              = module.networking.public_subnet_id
  key_pair_name          = var.key_pair_name
  app_security_group_id  = module.ec2_app.security_group_id
  ssh_allowed_cidrs      = var.ssh_allowed_cidrs
}

module "secrets" {
  source = "../../modules/secrets-manager"

  secret_name = "bankapp/prod-secrets"
  db_user     = var.db_user
  db_password = var.db_password
  ollama_url  = "http://${module.ec2_ollama.private_ip}:11434"
}

module "iam_oidc" {
  source = "../../modules/iam-oidc"

  project_name        = var.project_name
  github_org          = var.github_org
  github_repo         = var.github_repo
  allowed_branches    = var.allowed_branches
  secrets_manager_arn = module.secrets.secret_arn
}