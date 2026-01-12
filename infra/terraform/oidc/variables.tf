variable "region" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "role_name" {
  type = string
}

variable "allowed_subjects" {
  type = list(string)
}

variable "attach_admin_policy" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
