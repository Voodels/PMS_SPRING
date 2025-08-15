#!/usr/bin/env bash
set -euo pipefail

check() {
	name="$1"; url="$2"; expect="${3:-200}"
	code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
	if [[ "$code" == "$expect" || "$code" == "200" ]]; then
		echo "[OK] $name ($code)"
	else
		echo "[WARN] $name -> HTTP $code (expected $expect)"
	fi
}

echo "Checking container status:"
docker ps --format 'table {{.Names}}\t{{.Status}}' | sed 's/^/  /'

echo "\nProbing HTTP endpoints:"
check "Auth Service" http://localhost:3002/actuator/health 200 || true
check "Patient Service" http://localhost:4000/actuator/health 200 || true
check "Billing Service" http://localhost:5000/actuator/health 200 || true
check "Analytics Service" http://localhost:6000/actuator/health 200 || true
check "API Gateway" http://localhost:8081/actuator/health 200 || true

echo "Done."
