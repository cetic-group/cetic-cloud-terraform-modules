# Exemple — site statique ou images servis depuis un bucket

Sert un bucket **public** sous votre propre domaine, via une passerelle
applicative : un target group `kind = "bucket"`, une route (avec cache) et un
listener pour `www.example.com`. Aucun serveur, aucune clé, aucune IP à fournir.

Lecture seule (GET/HEAD), pas de listing du contenu du bucket.

## Utilisation

```bash
export TF_VAR_ccp_api_key="ccp_xxx"

terraform init
terraform plan
terraform apply
```

Puis créez un enregistrement DNS pour `www.example.com` chez votre
hébergeur. Contrôlez-le avec `cetic appgw listener dns-check`.

Si le bucket redevient privé, la sortie `origin_status` passe à `drift` (détail dans `origin_error`).
Déposez vos fichiers dans le dossier `site/` du bucket.

> Le provider doit être une version qui porte l'attribut `kind` de
> `ccp_appgw_target_group`.
