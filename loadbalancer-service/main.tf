resource "kubernetes_manifest" "service_loadbalancer" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "service_loadbalancer"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 8765
          "targetPort" = 9376
        },
      ]
      "selector" = {
        "app" = "kpmg"
      }
      "type" = "LoadBalancer"
    }
  }
}
