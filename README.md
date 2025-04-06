# Terraform Setup Instructions

## 1. Configure Terraform Variables

Replace all generic variables in `variables.tf` to suit your configuration. This includes settings like region, resource names, domain names, etc.
in `network.tf`, enter your AWS_PROFILE (aws cli profile)

## 2. Prepare Back-End Code

Zip the codebase of the back-end and place the `backend.zip` file in the same working directory as your Terraform files.

Example:

```bash
zip -r backend.zip ./path-to-backend-code
```
## 3. For Custom domain in GoDaddy:
Download the certificate, it usually come with "private.key",   "certificate.crt", "ca_bundle.crt".
Place them in terraform working directory.
Retrieve them via terraform
```hcl
resource "aws_acm_certificate" "godaddy_cert" {
  private_key       = file("private.key")
  certificate_body  = file("certificate.crt")
  certificate_chain = file("ca_bundle.crt")
}
```

