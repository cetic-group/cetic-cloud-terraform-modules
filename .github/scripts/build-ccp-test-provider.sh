#!/usr/bin/env bash
# CI-only installation. No Registry publication and no infrastructure access.
set -euo pipefail

provider_source="${1:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
output_dir="${2:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
provider_revision=bbddec69df9396ae71ca48ca558ff601da37a235

if [[ "$(git -C "$provider_source" rev-parse HEAD)" != "$provider_revision" ]]; then
  printf 'Unexpected provider revision; expected %s\n' "$provider_revision" >&2
  exit 1
fi

mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
platform="$(go env GOOS)_$(go env GOARCH)"
mirror="$output_dir/mirror"
package_dir="$mirror/registry.terraform.io/cetic-group/ccp/7.3.0/$platform"
mkdir -p "$package_dir"
go -C "$provider_source" build -trimpath -mod=readonly \
  -ldflags='-X main.version=7.3.0-dev.1733' \
  -o "$package_dir/terraform-provider-ccp_v7.3.0" .

cat > "$output_dir/terraform.tfrc" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "$mirror"
    include = ["registry.terraform.io/cetic-group/ccp"]
  }
  direct {
    exclude = ["registry.terraform.io/cetic-group/ccp"]
  }
}
EOF
printf 'Provider snapshot %s installed for %s\n' "$provider_revision" "$platform"
