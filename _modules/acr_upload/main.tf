resource "null_resource" "acrupload" {
  provisioner "local-exec" {
    when = create 
    command      = "az acr import --name ${var.acr_registry} --source ${var.source_registry}/${var.image}:${var.image_tag} --image ${var.image}:${var.image_tag} || true"
    on_failure  = fail
  }

  # provisioner "local-exec" {
  #   when = destroy
  #   command      = "az acr repository delete --name ${var.acr_registry} --repository ${var.image}:${var.image_tag} || true"
  # }

}

