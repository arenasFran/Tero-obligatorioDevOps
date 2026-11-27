terraform {
  backend "s3" {
    bucket       = "tero-tfstate-871694822674"
    key          = "test/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
