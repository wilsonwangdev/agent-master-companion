#!/bin/bash
set -euo pipefail

PORT=${1:-3001}
DIR="$(cd "$(dirname "$0")/../site" && pwd)"

echo "Serving site at http://localhost:$PORT"
echo "Directory: $DIR"
echo "Press Ctrl+C to stop"
echo ""

python3 -m http.server "$PORT" --directory "$DIR"
