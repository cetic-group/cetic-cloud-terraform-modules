# cetic-cloud-terraform-modules — CLAUDE.md

> Modules Terraform officiels pour CETIC Cloud Platform.
> Repo public : https://github.com/cetic-group/cetic-cloud-terraform-modules
> Provider consommé : `cetic-group/cetic-cloud-platform` (cf. `terraform-provider-cetic-cloud-platform/CLAUDE.md` pour la convention release).

---

## Convention bump version provider

À **chaque release** du provider Terraform `cetic-group/cetic-cloud-platform`
(nouveau tag `vX.Y.Z`), mettre à jour systématiquement :

1. **`versions.tf` de chaque module / landing-zone / example** :
   ```hcl
   required_providers {
     ccp = {
       source  = "cetic-group/cetic-cloud-platform"
       version = ">= X.Y.Z"
     }
   }
   ```
   Une commande pour bump tout :
   ```bash
   sed -i 's|version = ">= 0.8.1"|version = ">= 0.8.1"|g' \
     $(grep -rl "0.7.1" --include="*.tf" --include="*.md" .)
   ```

2. **`README.md` racine** — la version dans le snippet Quick Start.

3. Pour les **modules qui utilisent une nouvelle resource/datasource** introduite
   dans la release, ajouter le champ correspondant aux `variables.tf` + `main.tf`
   + `outputs.tf` + tests, puis bump le tag du repo modules en SemVer minor.

4. **Tests `terraform test`** : relancer après bump pour vérifier que les
   `mock_provider` blocks fonctionnent toujours (les attributs Computed
   nouvellement ajoutés peuvent demander un mock value).

### Workflow git

```bash
# 1. Une fois le provider tagué v0.8.0 (et publié sur Registry, ~5 min après tag)
git checkout -b chore/bump-provider-v0.8.0
sed -i 's|version = ">= 0.8.1"|version = ">= 0.8.1"|g' $(grep -rl "0.7.1" --include="*.tf" --include="*.md" .)

# 2. Ajouter aux modules les nouveaux champs / datasources si pertinent
# (ssh_key_ids dans container-scale-set, datasource ccp_db_pg_credentials
#  dans managed/database/pg, etc.)

# 3. Validate + test
make fmt && make validate && make test

# 4. Commit + PR + merge + tag SemVer
git commit -am "chore: bump provider constraint to >= 0.8.0 + new module fields"
git push -u origin chore/bump-provider-v0.8.0
gh pr create --title "chore: bump provider to v0.8.0" --body "..."
gh pr merge --squash --delete-branch
git tag -a v0.2.0 -m "v0.2.0 — provider 0.8.0 + scale-set ssh_key_ids + db credentials datasource"
git push origin v0.2.0
```

---

## Architecture

```
modules/
├── atomic/                # 1-1 avec le provider — primitives
│   ├── ssh-key/
│   ├── api-key/
│   ├── org-member/
│   ├── custom-template/
│   └── ipaas-pool/
├── network/
│   ├── vpc/               # VPC + VNets + IP reservations + firewall rules + peerings
│   ├── public-ip/
│   └── vpc-peering/
├── compute/
│   ├── container/
│   ├── container-scale-set/
│   ├── vm/
│   └── vm-scale-set/
├── storage/
│   ├── block-volume/
│   └── bucket/             # bucket + scoped keys
├── exposure/
│   └── load-balancer/
└── managed/
    ├── database/           # sous-modules pg / valkey / mysql / ferretdb
    └── k8s-cluster/

landing-zones/              # compositions org-ready
├── basic-web-app/          # 3-tier : VPC + LB + N containers + DB PG
├── k8s-platform/           # VPC + CCKS + ingress + DB
└── multi-region-ha/        # 3 régions + LB cross-region

examples/                   # usage simples (≤ 30 lignes)
├── quickstart-container/
├── web-3tier/
└── k8s-with-database/
```

---

## Conventions par module

### Layout standard d'un module

```
<module>/
├── versions.tf       # required_version + required_providers
├── variables.tf      # tous typés, tous avec validation si pertinent
├── main.tf           # 1 ressource principale ou composition
├── outputs.tf        # id + tous attributs cross-module utiles
├── README.md         # exemple + tableaux Inputs/Outputs
└── tests/            # optionnel — *.tftest.hcl avec mock_provider
    └── <module>.tftest.hcl
```

### Variables

- **Strictement typées** : `object({ … })` plutôt que `any`. Les sub-fields utilisent `optional(...)` du HCL 1.3+.
- **Validation** systématique pour :
  - Régions (`contains(["RNN", "PAR", "ABJ"], …)`)
  - Plans (`contains(["nano", "micro", "small", …], …)`)
  - CIDR (`can(cidrhost(v, 0))`)
  - Plages numériques (`x >= min && x <= max`)
- Variables sensibles : `sensitive = true` (passwords, tokens, clés privées).

### Outputs

- Toujours exposer `id` (UUID).
- Exposer tous les attributs Computed du provider qui peuvent servir downstream :
  - Pour un container : `ip_address`, `public_ip_address`, `cores`, `memory_mb`, `disk_gb`.
  - Pour un VPC : `vnet_ids` (map keyed par nom logique) pour piper vers d'autres modules.
- Output sensitive : marquer `sensitive = true` (ne JAMAIS commit en clair).

### Tests

Utiliser **`terraform test` natif** (HCL `.tftest.hcl`) avec `mock_provider`.
Pas d'`apply` réel — la CI tourne sans creds CCP.

```hcl
mock_provider "ccp" {
  mock_resource "ccp_vpc" {
    defaults = {
      id     = "00000000-0000-0000-0000-000000000001"
      status = "active"
    }
  }
}

run "creates_vpc" {
  command = plan
  variables {
    name   = "test"
    region = "RNN"
  }
  assert {
    condition     = ccp_vpc.this.name == "test"
    error_message = "Le nom du VPC doit refléter l'input."
  }
}
```

Tester aussi les cas d'échec (`expect_failures = [var.region]` quand un input
est invalide).

### Documentation

- README par module avec :
  - 1 exemple HCL en haut (copy-paste-ready)
  - Tableau Inputs (Name, Type, Required, Default, Description)
  - Tableau Outputs (Name, Sensitive, Description)
  - Section "Notes" pour les pièges (immutabilité, dépendances cross-module, etc.)
- Pas de génération auto via `terraform-docs` — conserver la flexibilité éditoriale.

---

## CI / Make targets

- `make fmt` / `make fmt-check` : format
- `make validate` : init + validate sur tous les modules
- `make lint` : tflint
- `make test` : `terraform test` natif sur tous les modules ayant un dossier `tests/`
- `make ci` : enchaîne tous les checks (le pipeline GitHub Actions appelle ce target)

CI workflow : `.github/workflows/ci.yml` (4 jobs : fmt, validate, lint, test).

---

## Dev local — `dev_overrides`

Pour développer sur le provider en parallèle, configurer un override dans
`~/.terraformrc` :

```hcl
provider_installation {
  dev_overrides {
    "cetic-group/cetic-cloud-platform" = "/home/coul/Documents/techledger/cetic-group/terraform-provider-cetic-cloud-platform"
  }
  direct {}
}
```

Et compiler le binaire avant chaque test :
```bash
cd /home/coul/Documents/techledger/cetic-group/terraform-provider-cetic-cloud-platform
go build -o ./terraform-provider-cetic-cloud-platform .
```

Avec ça, `terraform validate` et `terraform test` dans les modules utilisent
le binaire local — pratique pour itérer sur des modifs schema avant release.

---

## Versionnage

SemVer aligné conceptuellement avec le provider :
- `v0.1.x` : compatible provider `>= 0.7.1`
- `v0.2.x` : compatible provider `>= 0.8.0` (nouveaux champs scale-set / DB credentials)
- bump majeur `v1.0.0` quand le provider stabilise son API à `v1.x`
