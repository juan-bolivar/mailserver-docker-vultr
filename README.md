# Prerequisites

- Add a ticket for opening block 25 port in vultr [Blocked Ports](https://www.vultr.com/docs/what-ports-are-blocked/)
- Ansible and ansible-playbook
- Terraform v1.3.8
- Vultr API [Documentation](https://www.vultr.com/api/#section/Authentication/API%20Key)
- Add vultr nameservers to the domain registrar [Vultr Nameservers](https://www.vultr.com/docs/introduction-to-vultr-dns/#3__Set_the_Domain_s_Nameserver)


# Initial configuration

Create a variables.tf file in terraform directory with the following content:


```

variable "api_key" {
  default = "API_KEY"
}


variable "domain" {
  default = "DOMAIN"
}


variable "ssh_key_path_public" {
  default = "SSH_KEY_PATH.PUB"
}


variable "ssh_key_path_private" {
  default = "SSH_KEY_PATH"
}
```


# Run

To run use the following command:


```

make run

```


To destroy

```

make delete

```


