
locals {
  name = var.name == "" ? "" : join("-", [var.name, ""])
}
