terraform {
  backend s3 {
    bucket  = "boston-dsa-terraform"
    key     = "socialismbot.tfstate"
    region  = "us-east-1"
    profile = "bdsa"
  }
}
