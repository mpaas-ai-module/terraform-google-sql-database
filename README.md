# terraform-google-sql-database

### Build
Please use the below commands to run terraform.

```
terraform init --input=false
terraform plan
terraform apply
```

### Clean Up
To destroy the resources that you have created please use the below command.

```
terraform destroy
```

### Provider Dependencies
Providers are Terraform plugins that will be automatically installed during `terraform init` if available on the Terraform registry.
```
Terraform version >= 1.1.2
google(hashicorp/google) >= 4.1.0
```


### Module Dependencies
Dependencies are external modules that this module references. A module is considered external if it isn't within the same repository.

This module has no external module dependencies.

### Prerequisites
#### IAM Permissions
Please ensure the below IAM permissions are in place to create this module.
```
roles/cloudsql.admin
```

#### API Enablement
A project with the following APIs enabled must be used to host the resources of this module:

```
sqladmin.googleapis.com
```

### Inputs