# azure-packer-datadisk


## Step 1 - Create the Packer Image

This is a windows image with a data disk attached.


```sh
# Create the Azure Resource Group
az group create -l centralus -g tstraub-packer-images --tags="owner=tstraub"

# Create the Packer Image
packer build -var-file=example.pkrvar.hcl windows.pkr.hcl

# Azure Image Id will be printed
```

## Step 2 - Create the Azure VM from the Packer Image

This is the fun stuff.

Update the vars file:

```hcl
name                = "frompacker"
location            = "centralus"
azure_image_rg_name = ""
azure_image_name    = ""
```

`terraform apply`
