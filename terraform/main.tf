
# vultr_instance.mail:
resource "vultr_instance" "mail" {
  app_id      = 0
  backups     = "enabled"
  hostname    = "mail"
  os_id       = 477 # Debian 11
  plan        = "vc2-1c-1gb"
  region      = "mex"
  tags        = []
  ssh_key_ids = [vultr_ssh_key.main_ssh_key.id]
  backups_schedule {
    dom  = 0
    dow  = 1
    hour = 13
    type = "weekly"
  }

  timeouts {}
}

resource "vultr_dns_domain" "domain" {
  dns_sec    = "disabled"
  domain     = var.domain
  depends_on = [vultr_instance.mail]
}



resource "vultr_dns_record" "ns1" {
  data     = "ns1.vultr.com"
  name     = "ns1"
  domain   = vultr_dns_domain.domain.domain
  priority = -1
  ttl      = 300
  type     = "NS"
}


resource "vultr_dns_record" "ns2" {
  data = "ns2.vultr.com"
  name = "ns2"

  domain   = vultr_dns_domain.domain.domain
  priority = -1
  ttl      = 300
  type     = "NS"
}

resource "vultr_dns_record" "A_record" {
  name     = "@"
  data     = vultr_instance.mail.main_ip
  domain   = vultr_dns_domain.domain.domain
  priority = -1
  ttl      = 300
  type     = "A"
}

resource "vultr_dns_record" "CNAME" {
  domain   = vultr_dns_domain.domain.domain
  data     = var.domain
  name     = "*"
  priority = -1
  ttl      = 300
  type     = "CNAME"
}


resource "vultr_dns_record" "MX_1" {

  data     = vultr_instance.mail.main_ip
  domain   = vultr_dns_domain.domain.domain
  name     = "mail"
  priority = 1
  ttl      = 3600
  type     = "MX"
}



resource "vultr_dns_record" "MX_2" {
  data = vultr_instance.mail.main_ip

  domain   = vultr_dns_domain.domain.domain
  name     = "mail_2"
  priority = 1
  ttl      = 3600
  type     = "MX"
}




resource "vultr_dns_record" "spf" {

  data = "\"v=spf1 mx ip4:${vultr_instance.mail.main_ip} ~all\""


  domain   = vultr_dns_domain.domain.domain
  name     = "mail"
  priority = -1
  ttl      = 3600
  type     = "TXT"
}

resource "vultr_dns_record" "spf_2" {
  data = "\"v=spf1 mx ip4:${vultr_instance.mail.main_ip} ~all\""

  domain   = vultr_dns_domain.domain.domain
  priority = -1
  ttl      = 3600
  type     = "TXT"
  name     = "spf_2"
}


resource "vultr_ssh_key" "main_ssh_key" {
  name    = "main_ssh_key"
  ssh_key = file(var.ssh_key_path_public)
}


resource "null_resource" "instance_ready" {
  provisioner "remote-exec" {
    inline = ["echo all_ok"]
  }
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("${var.ssh_key_path_private}")
    host        = vultr_instance.mail.main_ip
  }

  depends_on = [vultr_instance.mail]

}

resource "null_resource" "ansible_config" {
  depends_on = [
    vultr_dns_record.A_record,
    vultr_dns_record.CNAME,
    vultr_dns_record.MX_1,
    vultr_dns_record.MX_2,
    vultr_dns_record.spf,
    vultr_dns_record.spf_2,
    vultr_dns_record.ns1,
    vultr_dns_record.ns2,
    vultr_instance.mail,
    null_resource.instance_ready,
  ]
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -u root -i '${vultr_instance.mail.main_ip},' -e 'cert_path=/etc/letsencrypt/certs' -e 'domain=${var.domain}' ../ansible/main.yaml --private-key=${var.ssh_key_path_private}"
  }
}

resource "vultr_dns_record" "domainkey" {
  data       = "v=DKIM1; h=sha256; k=rsa;p=${file("../ansible/dkim.output")}"
  domain     = vultr_dns_domain.domain.domain
  name       = "mail._domainkey"
  priority   = -1
  ttl        = 3600
  type       = "TXT"
  depends_on = [null_resource.ansible_config]
}
