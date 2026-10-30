#!/usr/bin/env bash
#
# Runs the spec suite of this project with testing.nvim:
#
#   scripts/test.sh                  every spec under TESTS/
#   scripts/test.sh --file config    only spec files whose name contains "config"
#   scripts/test.sh --json ir.json   also write the machine-readable result (the IR)
#   scripts/test.sh ci               the whole pipeline (`testing ci`: stylua, luacheck, the suite, ...)
#   scripts/test.sh ci --profile=fast   the quick check before a push; `ci verify`, `ci list` as well
#
# Everything else after the script name is handed to `testing run .` unchanged.
#
# Exit code 0: all specs passed. 1: a spec failed, OR nvim / the runner / a dependency was not
# found (the harness not running must never look like a green run; with `ci` that is exit 3, as
# `testing ci` reports it). Never waits silently.
# A dependency <name> is looked up in, in this order:
#   1. $<NAME>_DIR                  (testing.nvim -> $TESTING_NVIM_DIR, lib.nvim -> $LIB_NVIM_DIR)
#   2. <repo>/.deps/<name>          (what CI checks out)
#   3. <repo>/../<name>             (a sibling checkout)
#   4. stdpath('data')/lazy/<name>  (what a plugin manager installed)

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# The runner first, then what the project needs (this list is the `deps` of .testing.lua).
DEPS=('testing.nvim' 'lib.nvim' 'telescope.nvim' 'plenary.nvim')

# `ci`: a missing nvim, runner or dependency is infrastructure (exit 3, as `testing ci` reports it), not a failed step
FAIL_CODE=1
if [[ "${1:-}" == "ci" ]]; then
  FAIL_CODE=3
fi

fail() {
  printf '\033[31m%s\033[0m\n' "$1" >&2
  exit "$FAIL_CODE"
}

command -v nvim >/dev/null 2>&1 || fail "error: nvim is not on PATH."

# stdpath('data') of the default app name, computed before NVIM_APPNAME is changed below.
data_dir() {
  local app="${NVIM_APPNAME:-nvim}"
  if [[ -n "${LOCALAPPDATA:-}" ]]; then
    printf '%s' "$LOCALAPPDATA/$app-data"
  else
    printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/$app"
  fi
}
DATA="$(data_dir)"

marker_of() {
  case "$1" in
    lib.nvim) printf 'lua/lib/nvim' ;;
    testing.nvim) printf 'lua/testing' ;;
    *) printf 'lua' ;;
  esac
}

env_name_of() {
  printf '%s_DIR' "$(printf '%s' "$1" | tr 'a-z' 'A-Z' | tr -c 'A-Z0-9' '_')"
}

# A path as shown in an error message: one separator style on every platform (Git Bash would
# otherwise print /e/repos/x next to C:\Users\x\AppData\Local).
show_path() {
  if command -v cygpath >/dev/null 2>&1 && cygpath -m -- "$1" 2>/dev/null; then
    return 0
  fi
  printf '%s' "${1//\\//}"
}

# resolve <name>: sets RESOLVED, or exits 1 naming all four places.
resolve() {
  local name="$1" marker envname override
  marker="$(marker_of "$name")"
  envname="$(env_name_of "$name")"
  override="${!envname:-}"
  local p1="unset"
  [[ -n "$override" ]] && p1="$(show_path "$override")"
  local p2 p3 p4
  p2="$(show_path "$ROOT/.deps/$name")"
  p3="$(show_path "$ROOT/../$name")"
  p4="$(show_path "$DATA/lazy/$name")"

  if [[ -n "$override" ]]; then
    # An override that is set decides alone: it is never skipped for another checkout.
    if [[ -d "$override/$marker" ]]; then
      RESOLVED="$override"
      return 0
    fi
  else
    local dir
    for dir in "$ROOT/.deps/$name" "$ROOT/../$name" "$DATA/lazy/$name"; do
      if [[ -d "$dir/$marker" ]]; then
        RESOLVED="$dir"
        return 0
      fi
    done
  fi

  fail "error: dependency '$name' not found. Searched, in this order:
  1. \$$envname ($p1)
  2. .deps/$name ($p2)
  3. ../$name ($p3)
  4. stdpath('data')/lazy/$name ($p4)
Set \$$envname, or clone it to .deps/$name, or place it beside this repo."
}

DRIVER=""
for name in "${DEPS[@]}"; do
  resolve "$name"
  # The runner resolves the same dependencies itself; hand it exactly what was found here.
  export "$(env_name_of "$name")=$RESOLVED"
  if [[ "$name" == "testing.nvim" ]]; then
    DRIVER="$RESOLVED/scripts/testing.lua"
  fi
done
[[ -f "$DRIVER" ]] || fail "error: the runner entry is missing: $DRIVER"

# Throwaway app name: the run gets its own stdpath("config"/"data"/"state"), never the developer's.
# `ci`: the pipeline's document (ci.json) and the suite's stamp must land in the developer's real state directory,
# where `testing ci verify`, the pre-push hook and `:Testing ci status` read them. It is asked for BEFORE the throwaway
# app name and the scratch directory below and handed to `testing ci --state-dir` (an argument, not the environment:
# the specs must not inherit it).
real_state=""
if [[ "${1:-}" == "ci" ]]; then
  real_state="$(nvim -n -i NONE --headless -u NONE --cmd 'lua io.stdout:write(vim.fn.stdpath("state"))' --cmd 'qa!' 2>/dev/null)" || real_state=""
  [[ -n "$real_state" ]] || fail 'error: cannot ask nvim for stdpath("state"); the ci document would be lost.'
fi

# Always this name: an NVIM_APPNAME the developer exported (a second config) would make the run read and write that
# app's real stdpath("data"). The exported one only decides where a plugin manager's checkouts are (DATA, above).
export NVIM_APPNAME="cmdlog-tests"
# A run with `isolated = "none"` writes the plugin's state where Neovim keeps it: point state and
# cache at a scratch directory, removed afterwards (a child editor has a sandbox of its own).
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
if command -v cygpath >/dev/null 2>&1; then
  scratch="$(cygpath -m "$scratch")"
fi
export XDG_STATE_HOME="$scratch/state"
export XDG_CACHE_HOME="$scratch/cache"

# No `exec`: the trap must remove the scratch directory afterwards (`set -e` keeps the exit code).
# `scripts/test.sh surface --from ir.json --baseline surface.baseline.json`: the surface regression gate (docs/SURFACE.md)
if [ "${1:-}" = "surface" ]; then
  shift
  nvim -n -i NONE --headless -u NONE -l "$DRIVER" surface . "$@"
  exit $?
fi
# `scripts/test.sh conformance`: the conformance suite K1..K15 in the same environment (docs/CONFORMANCE.md of testing.nvim)
if [ "${1:-}" = "conformance" ]; then
  shift
  nvim -n -i NONE --headless -u NONE -l "$DRIVER" conformance . "$@"
  exit $?
fi
# `scripts/test.sh ci [--profile=fast] [...]`: the pipeline of the `ci` section, or the one derived from the repository
# (stylua, luacheck, the suite; docs/CI.md of testing.nvim), in the same environment. `ci verify`, `ci list` and
# `ci hook` are its subcommands: --state-dir goes after `verify` (it reads the proof there), the others take none.
if [ "${1:-}" = "ci" ]; then
  shift
  ci_args=()
  case "${1:-}" in
    verify)
      shift
      ci_args=(verify --state-dir "$real_state")
      ;;
    list | hook) ;;
    *) ci_args=(--state-dir "$real_state") ;;
  esac
  nvim -n -i NONE --headless -u NONE -l "$DRIVER" ci ${ci_args[@]+"${ci_args[@]}"} "$@"
  exit $?
fi
nvim -n -i NONE --headless -u NONE -l "$DRIVER" run . "$@"
