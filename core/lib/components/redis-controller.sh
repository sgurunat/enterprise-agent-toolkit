# Copyright (C) 2025-2026 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# ---------------------------------------------------------------------------
# deploy_redis_controller
#
# Deploys a standalone Redis Stack instance (with RediSearch) into the
# `redis` namespace using the bundled Helm chart at
# core/helm-charts/redis/.
#
# After deployment the in-cluster URL is:
#   redis://redis-stack-server.redis.svc.cluster.local:6379
#
# To point the Coding Agent at this shared instance instead of its own
# bundled Redis, deploy it with:
#   --set redis.enabled=false
#   --set redisUrl="redis://redis-stack-server.redis.svc.cluster.local:6379"
#
# Prerequisites:
#   • Kubernetes is running  (kubectl get nodes)
#   • SCRIPT_DIR points to the core/ directory
# ---------------------------------------------------------------------------
deploy_redis_controller() {
    local chart_path="${SCRIPT_DIR}/helm-charts/redis"
    local redis_ns="redis"

    echo "${BLUE}======================================================${NC}"
    echo "${BLUE}  Deploying Standalone Redis Stack${NC}"
    echo "${BLUE}======================================================${NC}"

    if [[ ! -d "${chart_path}" ]]; then
        echo "${RED}ERROR: Redis Helm chart not found at ${chart_path}${NC}"
        exit 1
    fi

    # Ensure Helm is available
    if ! command -v helm &>/dev/null; then
        echo "${CYAN}Installing Helm...${NC}"
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    echo "${CYAN}[1/3] Resolving Helm chart dependencies...${NC}"
    helm dependency build "${chart_path}" 2>&1 || \
        echo "${YELLOW}WARN: Dependency build had warnings — continuing.${NC}"

    echo "${CYAN}[2/3] Creating namespace '${redis_ns}'...${NC}"
    kubectl create namespace "${redis_ns}" --dry-run=client -o yaml | kubectl apply -f -

    echo "${CYAN}[3/3] Installing Redis Stack via Helm (namespace: ${redis_ns})...${NC}"
    local retries=3
    local attempt=1
    until helm upgrade --install redis "${chart_path}" \
        --namespace "${redis_ns}" \
        --set redis.redis_stack_server.storage_class="local-path" \
        --wait --timeout 10m; do
        if (( attempt >= retries )); then
            echo "${RED}ERROR: Redis installation failed after ${retries} attempts.${NC}"
            exit 1
        fi
        echo "${YELLOW}WARN: Helm timed out (attempt ${attempt}/${retries}), retrying...${NC}"
        (( attempt++ ))
        sleep 10
    done

    echo ""
    echo "${GREEN}============================================================${NC}"
    echo "${GREEN}  Redis Stack deployed successfully!${NC}"
    echo "${GREEN}  Namespace : ${redis_ns}${NC}"
    echo "${GREEN}  In-cluster URL: redis://redis-stack-server.redis.svc.cluster.local:6379${NC}"
    echo "${GREEN}============================================================${NC}"
}
