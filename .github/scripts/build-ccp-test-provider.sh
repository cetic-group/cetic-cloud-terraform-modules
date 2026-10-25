#!/usr/bin/env bash
# Test-only installation: no Registry publication and no infrastructure access.
set -euo pipefail
provider_source="${1:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
output_dir="${2:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
provider_revision=ce6fb0e6a6e9048355e35fc0fb6f76f2b0a90116
if [[ "$(git -C "$provider_source" rev-parse HEAD)" != "$provider_revision" ]]; then
  printf 'Unexpected provider revision; expected %s\n' "$provider_revision" >&2
  exit 1
fi
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
platform="$(go env GOOS)_$(go env GOARCH)"
mirror="$output_dir/mirror"
package_dir="$mirror/registry.terraform.io/cetic-group/ccp/8.0.0/$platform"
mkdir -p "$package_dir"
go -C "$provider_source" build -trimpath -mod=readonly \
  -ldflags='-X main.version=8.0.0-dev.1748' \
  -o "$package_dir/terraform-provider-ccp_v8.0.0" .
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
