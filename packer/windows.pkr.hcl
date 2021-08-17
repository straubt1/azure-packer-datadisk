variable "tenant_id" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}

variable "azure_resource_group_name" {}
variable "azure_region" {}

variable "name" {}

source "azure-arm" "basic" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  managed_image_resource_group_name = var.azure_resource_group_name
  managed_image_name                = format("%s-packer-image", var.name)

  temp_resource_group_name = format("%s-packer-temp-rg", var.name)

  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2019-datacenter-gensecond"
  os_type         = "Windows"


  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_username = "packer"


  azure_tags = {
    owner = var.name
  }

  location = var.azure_region
  vm_size  = "Standard_D2s_v3"

  disk_additional_size = [128]
}


build {
  sources = ["sources.azure-arm.basic"]

  provisioner "powershell" {
    inline = [
      // " # NOTE: the following *3* lines are only needed if the you have installed the Guest Agent.",
      // "  while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      // "  while ((Get-Service WindowsAzureTelemetryService).Status -ne 'Running') { Start-Sleep -s 5 }",
      // "  while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",

      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }

}
