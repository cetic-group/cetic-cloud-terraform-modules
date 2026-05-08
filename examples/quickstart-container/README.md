# Example — `quickstart-container`

L'exemple le plus minimal : un container Ubuntu 24.04 exposé sur internet via une IP publique directement attachée (pas de load balancer).

## Usage

```bash
export TF_VAR_ccp_api_key="cl_live_xxxxxxxxxxxx"

terraform init
terraform plan
terraform apply
```

Output : la commande SSH pour te connecter au container.

```bash
$ terraform output ssh_command
"ssh ubuntu@203.0.113.42"
```

## Cleanup

```bash
terraform destroy
```

## Coût indicatif

- 1 container `nano` (1 vCPU, 512 MB, 10 GB) : **0,003 €/h** (~2 €/mois)
- 1 IP publique : flat fee
- Egress sortant : gratuit

Soit **moins de 3 €/mois** pour un mini-VPS testable.
