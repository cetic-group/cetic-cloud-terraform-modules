# Landing zone `basic-web-app`

Compose une stack 3-tier complète prête à servir une application web :

```
                        Internet
                           │
                           ▼
                  ┌─────────────────┐
                  │  Public IP      │
                  │  (Orange pool)  │
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │  Load Balancer  │  ← VNet web (10.0.1.0/24)
                  │  HAProxy + VRRP │     firewall: HTTP/443 public
                  └────────┬────────┘
                           │
                  ┌────────▼────────┐
                  │ Container scale │
                  │ set (N replicas)│
                  │ port :8080      │
                  └────────┬────────┘
                           │ 5432
                  ┌────────▼────────┐
                  │ PostgreSQL HCP  │  ← VNet data (10.0.2.0/24)
                  │ (CNPG, isolated)│     firewall: PG depuis web only
                  └─────────────────┘
```

Composants créés :
- 1 clé SSH (`atomic/ssh-key`)
- 1 VPC + 2 VNets `web` (10.0.1.0/24) et `data` (10.0.2.0/24) avec firewall (`network/vpc`)
- 1 Container scale set (N replicas, plan configurable)
- 1 IP publique
- 1 Load balancer HTTP(S) avec backend = scale set
- 1 PostgreSQL managé (optionnel via `enable_database`)

## Exemple

```hcl
module "web_app" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//landing-zones/basic-web-app?ref=v0.1.0"

  org_prefix     = "acme"
  region         = "RNN"
  ssh_public_key = file("~/.ssh/id_ed25519.pub")

  app_replicas    = 3
  app_listen_port = 8080
  expose_https    = false

  enable_database = true
  db_plan         = "small"
  db_tier         = "prod"
}

output "url" {
  value = module.web_app.public_url
}

output "db_uri" {
  value     = module.web_app.database_uri
  sensitive = true
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `org_prefix` | string | required | Préfixe métier (`[a-z0-9-]+`, 3-32 chars). Préfixe toutes les ressources. |
| `region` | string | required | `RNN`, `PAR` ou `ABJ`. |
| `ssh_public_key` | string | required | Clé publique OpenSSH (`file("~/.ssh/id_ed25519.pub")`). |
| `app_plan` | string | `"small"` | Plan d'instance des containers. |
| `app_template` | string | `"ubuntu-24.04"` | Template OS. |
| `app_replicas` | number | `2` | Nombre de containers (1-20). |
| `app_listen_port` | number | `8080` | Port d'écoute de l'app sur le container. |
| `expose_https` | bool | `false` | Si `true`, ajoute un listener TCP/443. |
| `enable_database` | bool | `true` | Provisionne PostgreSQL managé. |
| `db_plan` | string | `"small"` | Plan PG. |
| `db_tier` | string | `"dev"` | `dev` (1 replica) ou `prod` (3 replicas HA). |
| `db_engine_version` | string | `"16"` | Version PG majeure. |
| `tags_extra` | list(string) | `[]` | Tags additionnels propagés partout. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `public_url` | no | URL publique HTTP de l'app. |
| `public_ip` | no | IP publique du LB. |
| `lb_id` | no | UUID du LB. |
| `vpc_id` | no | UUID du VPC. |
| `scale_set_id` | no | UUID du scale set. |
| `ssh_key_id` | no | UUID de la clé SSH. |
| `database_endpoint` | no | `host:port` PostgreSQL. |
| `database_admin_username` | no | Username admin PG. |
| `database_admin_password` | yes | Password admin PG. |
| `database_uri` | yes | URI complète `postgres://user:pass@host:port/db`. |

## Notes

- **CIDRs hardcodés** (`10.0.1.0/24` web, `10.0.2.0/24` data). Pour les modifier, copier la landing zone localement et l'ajuster — ces CIDRs sont volontairement opinionnated pour garder le composant démarrable en quelques lignes. Pour des topologies custom, utiliser directement le module `network/vpc`.
- **`db_tier` immutable** : pour upgrader `dev → prod`, snapshot + nouvelle instance + restore. Pas de migration in-place.
- **Le LB pointe sur le scale set** via `backend.scale_set_id` : les replicas qui scalent sont automatiquement ajoutés/retirés des backends côté HAProxy (reconcile beat task CETIC Cloud).
