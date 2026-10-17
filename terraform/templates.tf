# The Ubuntu 24.04 template is downloaded manually once via the Proxmox GUI
# (Datacenter -> node -> local -> CT Templates -> Templates -> Download),
# NOT managed by Terraform. Reason: this template file is static and rarely
# changes, and the proxmox_download_file resource has limitations (its `url`
# field forces replacement on import, see kb/architecture/terraform-strategy.md
# and kb/decisions/ADR-002-manual-template.md).
#
# If you reinstall Proxmox / move nodes, download it manually first
# before applying, then update the string below if the filename changed.

locals {
  template_ubuntu_2404 = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}