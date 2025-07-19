resource "null_resource" "acrupload" {
  for_each            = {for index, img in var.images : img.name => img}
  provisioner "local-exec" {
    when = create 
    command      = "az acr import --name ${each.value.acr_registry} --source ${each.value.registry}/${each.value.name}:${each.value.tag} --image ${each.value.name}:${each.value.tag} || true"
    on_failure  = fail
  }

  # provisioner "local-exec" {
  #   when = destroy
  #   command      = "az acr repository delete --name ${var.acr_registry} --repository ${var.image}:${var.image_tag} || true"
  # }

}

