provider "tls" {}

resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "client_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "server_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca_cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "My Cert Authority"
    organization = "My, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_cert_request" "client_request" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
        common_name  = "my.vpn.client"
        organization = "My, Inc"
  }
}
/*
 * Currently unused in vpn.tf.  However, this could replace the process for generating
 * a private certification authority, keys, and certificates for server and client. 
 */

resource "tls_cert_request" "server_request" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
        common_name  = "my.vpn.server"
        organization = "My, Inc"
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem   = tls_cert_request.client_request.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_request.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "server_acm" {
  private_key       = tls_private_key.server_key.private_key_pem
  certificate_body  = tls_locally_signed_cert.server_cert.cert_pem
  certificate_chain = tls_self_signed_cert.ca_cert.cert_pem
}

resource "aws_acm_certificate" "client_acm" {
  private_key       = tls_private_key.client_key.private_key_pem
  certificate_body  = tls_locally_signed_cert.client_cert.cert_pem
  certificate_chain = tls_self_signed_cert.ca_cert.cert_pem
}