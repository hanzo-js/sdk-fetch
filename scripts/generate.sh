#!/usr/bin/env bash
# The call site. Nothing about HOW this SDK is generated lives here.
#
# The invocation is logic and lives once, in hanzoai/openapi's `generate.py`;
# every per-language knob is data in `sdks.yaml` beside it. This file says
# "fetch, into this checkout" and nothing else.
#
#   ./scripts/generate.sh              # regenerate src/
#   ./scripts/generate.sh --check      # fail if committed src/ has drifted
#
# BOTH INPUTS ARRIVE AS VALUES. $SPEC is the document, already fetched at a
# pinned ref and digest-checked; $OPENAPI is the checkout holding the driver.
# hanzoai/ci's client lane sets both, because it holds the one credential that
# reads the forge.
#
# uv rather than a bare python3: the driver needs PyYAML and the runner image
# promises no interpreter at all, let alone one with it installed.
#
# Requires: java 17+, uv.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${OPENAPI:?the generator lives in hanzoai/openapi; the ci client lane sets OPENAPI, or point it at a checkout}"

if [ -n "${SPEC:-}" ]; then set -- --spec "$SPEC" "$@"; fi

exec uv run --with pyyaml python3 "$OPENAPI/generate.py" fetch --repo "$PWD" "$@"
