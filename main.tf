#get the data fro the global vars WS
data "terraform_remote_state" "global" {
  backend = "remote"
  config = {
    organization = "fqlcloudIST"
    workspaces = {
      name = var.globalwsname
    }
  }
}

variable "api_key" {
  type        = string
  description = "API Key"
}
variable "secretkey" {
  type        = string
  description = "Secret Key"
}
variable "globalwsname" {
  type        = string
  description = "TFC WS from where to get the params"
}
variable "mgmtcfgsshkeys" {
  type        = string
  description = "sshkeys"
}

variable "workerdesiredsize" {
  type        = string
  description = "worker desired size"
}

variable "clustername" {
  type        = string
  description = "cluster name"
}

data "intersight_organization_organization" "organization_moid" {
  name = local.organization
}

provider "intersight" {
  apikey    = var.api_key
  secretkey = var.secretkey
  endpoint  = "https://intersight.com"
}

# Intersight Provider Information
terraform {
  required_providers {
    intersight = {
      source = "ciscodevnet/intersight"
      version = "1.0.18"
    }
  }
}
module "terraform-intersight-iks" {

  source  = "terraform-cisco-modules/iks/intersight"
  version = "2.2"

  cluster = {
    name                = var.clustername
    action              = "Unassign"
    wait_for_completion = false
    worker_nodes        = var.workerdesiredsize
    load_balancers      = local.mgmtcfglbcnt
    worker_max          = local.workermaxsize
    control_nodes       = local.masterdesiredsize
    ssh_user            = local.mgmtcfgsshuser
    ssh_public_key      = var.mgmtcfgsshkeys
  }

  ip_pool = {
    use_existing        = true
    name                = local.ippoolmaster_list
  }

  sysconfig = {
    use_existing = true
    name         = local.syscfg_list
  }

  k8s_network = {
    use_existing = true
    name         = local.netcfg_list

  }

  versionPolicy = {
    useExisting = true
    policyName     = local.kubever_list
    #iksVersionName = local.kubever #"1.20.14-iks.0"
  }

  tr_policy = {
    use_existing = false
    create_new   = false
  }

  runtime_policy = {
    use_existing = false
    create_new   = false
  }

  infraConfigPolicy = {
    use_existing = true
    policyName   = local.infrapolname
    
  }

  instance_type = {
    use_existing = true
    name         = local.instancetypename
  }

  
  addons = [
    {     
     createNew = false
     addonPolicyName = "monitor"
     addonName            = "ccp-monitor"
     description       = "monitor Policy"
     # upgradeStrategy  = "AlwaysReinstall"
     # installStrategy  = "InstallOnly"
     # releaseVersion = "0.2.61-helm3"
     # overrides = yamlencode({"demoApplication":{"enabled":true}})
     } ]
  
  organization = local.organization
}


  
locals {
  organization= yamldecode(data.terraform_remote_state.global.outputs.organization)
  ippool_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  netcfg_list = yamldecode(data.terraform_remote_state.global.outputs.network_pod)
  syscfg_list = yamldecode(data.terraform_remote_state.global.outputs.network_service)
  clustername = yamldecode(data.terraform_remote_state.global.outputs.clustername)
  mgmtcfgetcd = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfgetcd)
  mgmtcfglbcnt = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfglbcnt)
  mgmtcfgsshuser = yamldecode(data.terraform_remote_state.global.outputs.mgmtcfgsshuser)
  ippoolmaster_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  ippoolworker_list = yamldecode(data.terraform_remote_state.global.outputs.ip_pool_policy)
  kubever_list = yamldecode(data.terraform_remote_state.global.outputs.k8s_version_name)
  kubever = yamldecode(data.terraform_remote_state.global.outputs.k8s_version)
  infrapolname = yamldecode(data.terraform_remote_state.global.outputs.infrapolname)
  instancetypename = yamldecode(data.terraform_remote_state.global.outputs.instancetypename)
  mastergrpname = yamldecode(data.terraform_remote_state.global.outputs.mastergrpname)
  masterdesiredsize = yamldecode(data.terraform_remote_state.global.outputs.masterdesiredsize)
  masterinfraname = yamldecode(data.terraform_remote_state.global.outputs.masterinfraname)
  workergrpname = yamldecode(data.terraform_remote_state.global.outputs.workergrpname)
  workerdesiredsize = yamldecode(data.terraform_remote_state.global.outputs.workerdesiredsize)
  workerinfraname = yamldecode(data.terraform_remote_state.global.outputs.masterinfraname)
  workermaxsize = yamldecode(data.terraform_remote_state.global.outputs.workermaxsize)
}
