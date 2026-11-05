#!/usr/bin/env bash
# Test-only installation: no Registry publication and no infrastructure access.
set -euo pipefail
provider_source="${1:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
output_dir="${2:?Usage: build-ccp-test-provider.sh SOURCE OUTPUT}"
provider_revision=400cf09a8d9bc517817808f1e7565ebdfc2ba52f
if [[ "$(git -C "$provider_source" rev-parse HEAD)" != "$provider_revision" ]]; then
  printf 'Unexpected provider revision; expected %s\n' "$provider_revision" >&2
  exit 1
fi
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
platform="$(go env GOOS)_$(go env GOARCH)"
mirror="$output_dir/mirror"
package_dir="$mirror/registry.terraform.io/cetic-group/ccp/8.1.0/$platform"
mkdir -p "$package_dir"
go -C "$provider_source" build -trimpath -mod=readonly \
  -ldflags='-X main.version=8.1.0-dev.1828' \
  -o "$package_dir/terraform-provider-ccp_v8.1.0" .
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
