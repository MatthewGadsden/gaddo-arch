#!/usr/bin/env bash
# Preview the startup greeting for each machine, straight from the repo.
# Nothing in ~/.config or ~/.bashrc is touched.
#
#   install/preview-greeting.sh          # every <host>-poster.ans in the repo
#   install/preview-greeting.sh appa     # just one
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() { echo "error: $*" >&2; exit 1; }

if (($#)); then
  hosts=("$@")
else
  hosts=()
  for f in "$REPO_DIR"/*-poster.ans; do
    name="$(basename "$f")"
    hosts+=("${name%-poster.ans}")
  done
fi

for host in "${hosts[@]}"; do
  art="$REPO_DIR/$host-poster.ans"
  [[ -f $art ]] || die "no art for '$host' ($art)"
  printf '\n==> %s\n' "$host"
  # point the greeting at the repo copies and show the previewed hostname in its title
  sed -e "s|~/.config/akame-poster.ans|$art|" \
      -e "s|~/.config/tokyo-snow.theme|$REPO_DIR/tokyo-snow.theme|" \
      "$REPO_DIR/sloth-greeting.sh" | HOSTNAME="$host" bash
done
