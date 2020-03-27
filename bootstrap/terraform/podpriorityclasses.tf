resource "kubernetes_priority_class" "ep_high" {
  metadata {
    name = "ep-high"
  }

  value = 10000
}

resource "kubernetes_priority_class" "ep_medium_high" {
  metadata {
    name = "ep-medium-high"
  }

  value = 7500
}

resource "kubernetes_priority_class" "ep_medium" {
  metadata {
    name = "ep-medium"
  }

  value = 5000
}

resource "kubernetes_priority_class" "ep_medium_low" {
  metadata {
    name = "ep-medium-low"
  }

  value = 2500
}

resource "kubernetes_priority_class" "ep_low" {
  metadata {
    name = "ep-low"
  }

  value = 100
}