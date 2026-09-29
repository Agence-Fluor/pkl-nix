#!/bin/sh
set -eu

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT HUP INT TERM

pkl eval "$repo/tests/all-outputs.pkl" > "$temp/first.nix"
pkl eval "$repo/tests/all-outputs.pkl" > "$temp/second.nix"
cmp "$temp/first.nix" "$temp/second.nix"
nix-instantiate --parse "$temp/first.nix" > /dev/null
grep -Fq 'Escaped \${literal}' "$temp/first.nix"
pkl eval "$repo/tests/raw-outputs.pkl" > "$temp/raw.nix"
nix-instantiate --parse "$temp/raw.nix" > /dev/null
grep -Fq 'answer = 42' "$temp/raw.nix"
pkl eval "$repo/flake.pkl" > "$temp/self.nix"
nix-instantiate --parse "$temp/self.nix" > /dev/null

sh "$repo/scripts/package-pkl.sh" "$temp/dist"
version=$(pkl eval --no-project -x 'package.version' "$repo/PklProject")
archive="$temp/dist/pkl-nix@$version.zip"
files=$(unzip -Z1 "$archive" | sort)
test "$files" = "$(printf 'Flake.pkl\nNix.pkl')"
mkdir -p "$temp/package"
unzip -q "$archive" -d "$temp/package"
cp "$repo/PklProject" "$temp/package/PklProject"
mkdir -p "$temp/consumer"
cat > "$temp/consumer/PklProject" <<'EOF'
amends "pkl:Project"

dependencies {
  ["nix"] = import("../package/PklProject")
}
EOF
cat > "$temp/consumer/flake.pkl" <<'EOF'
amends "@nix/Flake.pkl"
import "@nix/Nix.pkl" as Nix

description = "packaged"
packages {
  ["x86_64-linux"] { ["default"] = new Nix.Raw { code = "null" } }
}
EOF
cd "$temp/consumer"
pkl project resolve > /dev/null
pkl eval flake.pkl > "$temp/consumer.nix"
nix-instantiate --parse "$temp/consumer.nix" > /dev/null
grep -Fq 'description = "packaged"' "$temp/consumer.nix"
printf 'pkl-nix package tests passed\n'
