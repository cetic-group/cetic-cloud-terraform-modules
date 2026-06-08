# Module `atomic/appgw-target-group`

Wrapper autour de `ccp_appgw_target_group` + `ccp_appgw_target_group_member`. Un target group est un **pool de backends** partageant un même algorithme et un même health check L7. Les members peuvent être des containers, des VMs ou des IPs raw dans le même VNet que l'AppGW.

> **🇬🇧** Wraps `ccp_appgw_target_group` + `ccp_appgw_target_group_member`. A target group is a pool of backends sharing one algorithm and one L7 health check. Members can be container instances, VMs, or raw VNet IPs.

## Exemple — pool de containers

```hcl
module "tg_api" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-target-group?ref=v0.8.0"

  appgw_id = module.appgw.id
  name     = "api-pool"

  algorithm = "leastconn"

  health_check = {
    protocol      = "http"
    path          = "/healthz"
    expect_status = 200
    interval_sec  = 10
  }

  members = {
    api_01 = { container_id = ccp_container_instance.api_01.id, port = 8080 }
    api_02 = { container_id = ccp_container_instance.api_02.id, port = 8080 }
    api_03 = { container_id = ccp_container_instance.api_03.id, port = 8080, weight = 50 }
  }
}
```

## Exemple — pool mixte (VM + IP raw) avec sticky session

```hcl
module "tg_legacy" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-target-group?ref=v0.8.0"

  appgw_id = module.appgw.id
  name     = "legacy-pool"

  algorithm          = "source"
  sticky_enabled     = true
  sticky_cookie_name = "JSESSIONID"

  health_check = {
    protocol     = "https"
    path         = "/status"
    interval_sec = 30
    timeout_sec  = 10
  }

  members = {
    legacy_vm   = { vm_instance_id = ccp_vm_instance.legacy.id, port = 8443 }
    bare_metal  = { target_ip = "10.0.1.42", port = 8443, weight = 200 }
  }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `appgw_id` | string | yes | — | UUID de l'AppGW parente. |
| `name` | string | yes | — | Nom du target group, unique par AppGW. |
| `algorithm` | string | no | `"roundrobin"` | `roundrobin` / `leastconn` / `source` / `random`. |
| `health_check` | object | no | `{}` (défauts) | Voir schéma. |
| `sticky_enabled` | bool | no | `false` | Cookie-based session affinity. |
| `sticky_cookie_name` | string | no | `null` | Requis si `sticky_enabled=true`. |
| `members` | map(object) | no | `{}` | Map de members (voir schéma). |

### Schéma `health_check`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `protocol` | string | `"http"` | `http` / `https` / `tcp`. |
| `method` | string | `"GET"` | Méthode HTTP. |
| `path` | string | `"/"` | Path à hit. |
| `expect_status` | number | `200` | Code HTTP attendu. |
| `interval_sec` | number | `5` | 1-300. |
| `timeout_sec` | number | `3` | 1-60. |
| `healthy_threshold` | number | `2` | 1-10. |
| `unhealthy_threshold` | number | `3` | 1-10. |

### Schéma `members[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `container_id` | string | XOR | UUID container. |
| `vm_instance_id` | string | XOR | UUID VM. |
| `target_ip` | string | XOR | IP raw dans le VNet (IPv4). |
| `port` | number | required | 1-65535. |
| `weight` | number | `100` | 0-1000. |
| `enabled` | bool | `true` | Désactivable sans retirer du HCL. |

Exactement un de `container_id` / `vm_instance_id` / `target_ip` est requis.

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du target group. |
| `name` | Nom. |
| `appgw_id` | UUID de la gateway parente. |
| `algorithm` | Algorithme effectif. |
| `member_ids` | Map keyed par label → UUID member. |

## Notes

- **Map vs liste pour `members`** : les clés de map sont stables → un member réordonné dans le code n'est pas détruit/recréé. À l'inverse, une liste reorderée force des replacement.
- **`enabled=false`** : retire le backend du pool sans le détruire (utile pour drain progressif avant retrait définitif).
- **Health check `tcp`** : ignore `method` / `path` / `expect_status` — seul un open de socket valide le member.
