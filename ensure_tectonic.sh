#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tools_dir="$root_dir/.tools/tectonic"
tectonic_bin="$tools_dir/tectonic"

if [[ -x "$tectonic_bin" ]]; then
  echo "$tectonic_bin"
  exit 0
fi

for bin in curl tar uname; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Error: missing required tool: $bin" >&2
    exit 1
  fi
done

arch="$(uname -m)"
sys="$(uname -s)"

case "$sys" in
  Linux)
    case "$arch" in
      x86_64|amd64) asset="tectonic-0.15.0-x86_64-unknown-linux-gnu.tar.gz" ;;
      aarch64|arm64) asset="tectonic-0.15.0-aarch64-unknown-linux-gnu.tar.gz" ;;
      *)
        echo "Error: unsupported Linux architecture: $arch" >&2
        exit 1
        ;;
    esac
    ;;
  Darwin)
    case "$arch" in
      x86_64|amd64) asset="tectonic-0.15.0-x86_64-apple-darwin.tar.gz" ;;
      arm64) asset="tectonic-0.15.0-aarch64-apple-darwin.tar.gz" ;;
      *)
        echo "Error: unsupported macOS architecture: $arch" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Error: unsupported system: $sys" >&2
    exit 1
    ;;
esac

mkdir -p "$tools_dir"
tmp_dir="$(mktemp -d -t xdu_beamer_tectonic_XXXXXX)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

url="https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.15.0/${asset}"
archive="$tmp_dir/$asset"

curl -L "$url" -o "$archive"
tar -xzf "$archive" -C "$tmp_dir"

found_bin="$(find "$tmp_dir" -type f -name tectonic | head -n 1)"
if [[ -z "$found_bin" ]]; then
  echo "Error: failed to extract tectonic binary" >&2
  exit 1
fi

cp "$found_bin" "$tectonic_bin"
chmod +x "$tectonic_bin"

echo "$tectonic_bin"
