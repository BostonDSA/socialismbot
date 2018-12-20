terraform {
  backend s3 {
    bucket  = "terraform.bostondsa.org"
    key     = "socialismbot-modules.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}
