provider "tls" {}

/* 
 * Create the self-signed TLS certificate and move it to the AWS Certificate Manager.  You could do 
 * this manually as well.  If you have a production certificate you would upload it to the ACM
 * and then look it up by name and apply it here.  The client-vpn module has an example of looking
 * up a cert.
 */
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "dev.internal"
    organization = "Developers, Inc"
  }

  validity_period_hours = 72

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.private_key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
}