# resource "kubernetes_namespace" "ns" {
#   count       = var.enable == true ? 1 : 0
#   metadata {
#     name = var.application_namespace
#   }
# }

resource "helm_release" "kv_mount" {
  count      = var.enable == true ? 1 : 0 
  #depends_on = [ kubernetes_namespace.ns ]
  name       = "${var.kv_name}"
  chart      = format("%s/helm", path.module)
  namespace  = "${var.application_namespace}"
  version    = "${var.application_version}"

  set {
    name  = "application.name"
    value = "${var.application_name}"
  }
  set {
    name  = "application.namespace"
    value = "${var.application_namespace}"
  }
  set {
    name  = "application.version"
    value = "${var.application_version}"
  }

  set {
    name  = "k8secret.name"
    value = "${var.kv_name}"
  }
  set {
    name  = "k8secret.providerClassName"
    value = "${var.kv_name}"
  }

  set {
    name  = "keyVault.name"
    value = "${var.kv_name}"
  }  
  set {
    name  = "keyVault.kvCsiClientId"
    value = "${var.kv_csi_client_id}"
  }
  set {
    name  = "keyVault.tenantId"
    value = "${var.kv_tenant_id}"
  }

  set {
    name  = "keyVault.secrets.key1"
    value = "${var.key1}"
  }
  set {
    name  = "keyVault.secrets.key2"
    value = "${var.key2}"
  }
  set {
    name  = "keyVault.secrets.key3"
    value = "${var.key3}"
  }
  set {
    name  = "keyVault.secrets.key4"
    value = "${var.key4}"
  }
  set {
    name  = "keyVault.secrets.key5"
    value = "${var.key5}"
  }
  set {
    name  = "keyVault.secrets.key6"
    value = "${var.key6}"
  }
  set {
    name  = "keyVault.secrets.key7"
    value = "${var.key7}"
  }
  set {
    name  = "keyVault.secrets.key8"
    value = "${var.key8}"
  }
  set {
    name  = "keyVault.secrets.key9"
    value = "${var.key9}"
  }
  set {
    name  = "keyVault.secrets.key10"
    value = "${var.key10}"
  }
  set {
    name  = "keyVault.secrets.key11"
    value = "${var.key11}"
  }
  set {
    name  = "keyVault.secrets.key12"
    value = "${var.key12}"
  }
  set {
    name  = "keyVault.secrets.key13"
    value = "${var.key13}"
  }
  set {
    name  = "keyVault.secrets.key14"
    value = "${var.key14}"
  }
  set {
    name  = "keyVault.secrets.key15"
    value = "${var.key15}"
  }
  set {
    name  = "keyVault.secrets.key16"
    value = "${var.key16}"
  }
  set {
    name  = "keyVault.secrets.key17"
    value = "${var.key17}"
  }
  set {
    name  = "keyVault.secrets.key18"
    value = "${var.key18}"
  }
  set {
    name  = "keyVault.secrets.key19"
    value = "${var.key19}"
  }
  set {
    name  = "keyVault.secrets.key20"
    value = "${var.key20}"
  }
  set {
    name  = "keyVault.secrets.key21"
    value = "${var.key21}"
  }
  set {
    name  = "keyVault.secrets.key22"
    value = "${var.key22}"
  }
  set {
    name  = "keyVault.secrets.key23"
    value = "${var.key23}"
  }
  set {
    name  = "keyVault.secrets.key24"
    value = "${var.key24}"
  }
  set {
    name  = "keyVault.secrets.key25"
    value = "${var.key25}"
  }
  set {
    name  = "keyVault.secrets.key26"
    value = "${var.key26}"
  }
  set {
    name  = "keyVault.secrets.key27"
    value = "${var.key27}"
  }
    set {
    name  = "keyVault.secrets.key28"
    value = "${var.key28}"
  }
    set {
    name  = "keyVault.secrets.key29"
    value = "${var.key29}"
  }
    set {
    name  = "keyVault.secrets.key30"
    value = "${var.key30}"
  }
    set {
    name  = "keyVault.secrets.key31"
    value = "${var.key31}"
  }
    set {
    name  = "keyVault.secrets.key32"
    value = "${var.key32}"
  }
    set {
    name  = "keyVault.secrets.key33"
    value = "${var.key33}"
  }
    set {
    name  = "keyVault.secrets.key34"
    value = "${var.key34}"
  }
    set {
    name  = "keyVault.secrets.key35"
    value = "${var.key35}"
  }
}
