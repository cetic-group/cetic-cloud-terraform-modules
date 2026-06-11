# Exemple — accès VPN privé

Compose un VPC et une passerelle d'**accès VPN privé** pour joindre les ressources
privées du VPC depuis des postes distants, sans rien exposer sur Internet.

Deux clients sont enregistrés :
- `alice` — fournit sa propre clé publique (recommandé : aucune clé privée ne
  transite par la plateforme ni par le state).
- `laptop-ci` — configuration générée par la plateforme et stockée dans le state.

## Usage

```bash
export TF_VAR_ccp_api_key="ccp-..."
export TF_VAR_alice_public_key="..."   # clé publique générée et fournie par Alice côté client

terraform init
terraform apply
```

Récupérer le point d'entrée et la config générée :

```bash
terraform output vpn_endpoint
terraform output -raw vpn_peer_configs
```

## Versions

| Composant | Version |
|---|---|
| Provider `cetic-group/ccp` | `>= 4.4.0` |
| Terraform | `>= 1.7` |
