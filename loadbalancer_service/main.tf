resource "kubernetes_manifest" "service_example_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "example-service"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 8765
          "targetPort" = 9376
        },
      ]
      "selector" = {
        "app" = "example"
      }
      "type" = "LoadBalancer"
    }
  }
}
