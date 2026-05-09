# Module `exposure/load-balancer`

Wrapper riche autour de `ccp_load_balancer` qui expose `listeners` comme une map of object(map de backends), évitant les `dynamic "listener" { dynamic "backend" }` à la main dans tout le code consommateur.

## Exemple

```hcl
module "lb_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.1.0"
  region = "RNN"
}

module "lb" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/exposure/load-balancer?ref=v0.1.0"

  name         = "web-lb"
  region       = "RNN"
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.lb_public_ip.id
  tags         = ["web", "env:prod"]

  listeners = {
    http = {
      algorithm     = "round_robin"
      protocol      = "http"
      frontend_port = 80
      backends = {
        web_01 = { container_id = ccp_container_instance.web_01.id, port = 8080, weight = 1 }
        web_02 = { container_id = ccp_container_instance.web_02.id, port = 8080, weight = 1 }
        web_03 = { container_id = ccp_container_instance.web_03.id, port = 8080, weight = 1 }
      }
    }
    https = {
      algorithm     = "round_robin"
      protocol      = "tcp"
      frontend_port = 443
      backends = {
        web_01 = { container_id = ccp_container_instance.web_01.id, port = 8443 }
        web_02 = { container_id = ccp_container_instance.web_02.id, port = 8443 }
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
| `public_ip_id` | string | no | `null` | IP publique à attacher. |
| `tags` | list(string) | no | `[]` | |
| `listeners` | map(object) | no | `{}` | Voir schéma ci-dessous. |

### Schéma `listeners[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `algorithm` | string | `"round_robin"` | `round_robin` / `least_conn` / `source_ip`. |
| `protocol` | string | `"tcp"` | `http` / `tcp`. |
| `frontend_port` | number | required | 1-65535. |
| `backends` | map(object) | required | Map de backends. |

### Schéma `backends[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `container_id` | string | XOR | UUID container. |
| `vm_instance_id` | string | XOR | UUID VM. |
| `port` | number | required | Port destination. |
| `weight` | number | `1` | Poids du backend. |

Exactement un de `container_id` / `vm_instance_id` est requis.

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du LB. |
| `vip_address` | VIP privée. |
| `public_ip_address` | IP publique attachée. |
| `status` | |

## Notes

- HA inter-node automatique (par défaut).
- `scale_set_id` comme backend pas encore exposé par le provider (cf. backlog v0.8.0).
- Les backends sont fully reconciled à chaque apply : un backend retiré du HCL = retrait sans downtime.
