# Module `exposure/load-balancer`

Wrapper riche autour de `ccp_load_balancer` qui expose `listeners` comme une map of object (map de backends), évitant les `dynamic "listener" { dynamic "backend" }` à la main dans tout le code consommateur. Supporte les certificats Let's Encrypt automatiques (ACME) sur les listeners `https`.

## Exemple — HTTP + HTTPS avec cert Let's Encrypt (HTTP-01)

```hcl
module "lb_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.23.0"
  region = "RNN"
}

module "lb" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/exposure/load-balancer?ref=v0.23.0"

  name         = "web-lb"
  region       = "RNN"
  plan         = "medium" # small (défaut) | medium | large
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.lb_public_ip.id
  tags         = ["web", "env:prod"]

  listeners = {
    http = {
      protocol    = "http"
      listen_port = 80
      backends = {
        web_01 = { container_id = ccp_container_instance.web_01.id, port = 8080, weight = 1 }
        web_02 = { container_id = ccp_container_instance.web_02.id, port = 8080, weight = 1 }
      }
    }
    https = {
      protocol       = "https"
      listen_port    = 443
      algorithm      = "roundrobin"
      domain         = "www.example.com"
      acme_challenge = "http01"
      backends = {
        web_01 = { container_id = ccp_container_instance.web_01.id, port = 8080 }
        web_02 = { container_id = ccp_container_instance.web_02.id, port = 8080 }
      }
    }
  }
}
```

## Exemple — HTTPS avec challenge DNS-01 (domaine client)

```hcl
variable "cloudflare_token" {
  type      = string
  sensitive = true
}

module "lb" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/exposure/load-balancer?ref=v0.23.0"

  name    = "api-lb"
  region  = "RNN"
  vnet_id = module.vpc.vnet_ids.web

  listeners = {
    https = {
      protocol          = "https"
      listen_port       = 443
      domain            = "api.example.com"
      acme_challenge    = "dns01"
      acme_dns_provider = "cloudflare"
      acme_dns_credentials = {
        api_token = var.cloudflare_token
      }
      backends = {
        api_01 = { container_id = ccp_container_instance.api.id, port = 8080 }
      }
    }
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom du LB. |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `vnet_id` | string | yes | — | VNet hébergeant la VIP. |
| `plan` | string | no | `"small"` | Plan de capacité : `small` (1 vCPU/512 Mo, 4,99 €), `medium` (2 vCPU/1 Go, 11,99 €), `large` (4 vCPU/2 Go, 27,99 €). **Immuable** — `RequiresReplace` côté provider. |
| `public_ip_id` | string | no | `null` | IP publique à attacher. |
| `tags` | list(string) | no | `[]` | |
| `listeners` | map(object) | no | `{}` | Voir schéma ci-dessous. La clé est un label logique (non envoyé à l'API). |

### Schéma `listeners[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `protocol` | string | `"tcp"` | `tcp` / `http` / `https`. **Immuable**. |
| `listen_port` | number | required | Port d'écoute du LB (1-65535). **Immuable**. |
| `algorithm` | string | `"roundrobin"` | `roundrobin` / `leastconn` / `source`. **Immuable**. |
| `health_check_enabled` | bool | `true` | Active les health checks backend. |
| `health_check_path` | string | `null` | Chemin HTTP des health checks (`http`/`https`). |
| `domain` | string | `null` | FQDN servi par un listener `https`. Requis si `acme_challenge` set. Lowercase. |
| `acme_challenge` | string | `null` | `http01` / `dns01` — émission auto Let's Encrypt. Requiert `protocol = "https"` + `domain`. |
| `acme_dns_provider` | string | `null` | Clé du provider DNS pour `dns01` (ex. `cloudflare`). |
| `acme_dns_credentials` | map(string) | `null` | Credentials DNS pour `dns01` (sensible, write-only). |
| `backends` | map(object) | required | Map de backends. |

### Schéma `backends[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `container_id` | string | XOR | UUID container. |
| `vm_instance_id` | string | XOR | UUID VM. |
| `port` | number | required | Port destination. |
| `weight` | number | `1` | Poids du backend (réconcilié en place). |

Exactement un de `container_id` / `vm_instance_id` est requis.

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du LB. |
| `vip_address` | VIP privée. |
| `public_ip_address` | IP publique attachée. |
| `status` | `provisioning` / `active` / `updating` / `error`. |
| `created_at` | Timestamp RFC 3339 de création. |

## Notes

- HA inter-node automatique (par défaut).
- **Listeners immuables** : tout changement d'un champ listener autre que ses backends (protocol, port, algorithm, domain, réglages ACME) force un remplacement complet du LB.
- **Backends réconciliés en place** : ajout/retrait/changement de `weight` d'un backend ne remplace pas le LB.
- **ACME** requiert `protocol = "https"` + `domain`. Pour `dns01`, fournir aussi `acme_dns_provider` + `acme_dns_credentials`. Découvrir les providers DNS supportés via la data source `ccp_acme_dns_providers`.
