module "web-servers" {
  source   = "../childs/web-servers"
  for_each = toset(var.compute_name)

  compute_name = each.value

}

