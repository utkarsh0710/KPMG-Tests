terraform {
 backend "gcs" {
   bucket  = "tfstate"
   prefix  = "3_tier_app"
 }
}