resource "aws_config_conformance_pack" "cmmc_level3_conformance_pack" {
  name          = "operational-best-practices-for-cmmc-level3"
  template_body = data.http.conformance_pack.body

  depends_on = [aws_config_configuration_recorder.config_recorder]
}

data "http" "conformance_pack" {
  url = "https://raw.githubusercontent.com/awslabs/aws-config-rules/master/aws-config-conformance-packs/Operational-Best-Practices-for-CMMC-Level-3.yaml"
}