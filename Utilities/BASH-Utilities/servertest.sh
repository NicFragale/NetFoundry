#!/usr/bin/env bash

# ─── Config ───────────────────────────────────────────────────────────────────
CONNECT_TIMEOUT=3
declare -A ENTRIES
declare -a ORDER

# ─── ANSI colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

add_entry() {
    local label="$1"; shift
    ENTRIES["$label"]="$*"
    ORDER+=("$label")
}

# ─── Define your DNS entries ──────────────────────────────────────────────────
# Frontdoor Network
add_entry "FD | Network Controller" \
    "ca26ea8c-35f2-4d1b-bb35-15977e5cd5d0.production.netfoundry.io" \
    "ca26ea8c-35f2-4d1b-bb35-15977e5cd5d0-p.production.netfoundry.io"
add_entry "FD | Hosted Edge Router 1" \
    "bd4de47a-8e59-47c2-8c43-7ca9494e5102.production.netfoundry.io"
add_entry "FD | Hosted Edge Router 2" \
    "9c568ba5-15a7-4992-ae27-e58d03068fbb.production.netfoundry.io"
add_entry "FD | Hosted Edge Router 3" \
    "e2c40f8e-f3e5-4c7f-8f2a-27eb64126b10.production.netfoundry.io"
add_entry "FD | Frontdoor Agent API" \
    "api-v2.frontdoor.production.netfoundry.io"
add_entry "FD | NF Gateway" \
    "gateway.production.netfoundry.io"
add_entry "FD | Installation Scripts" \
    "get.netfoundry.io"
add_entry "FD | Package Repository" \
    "netfoundry.jfrog.io"

# ─── Header ───────────────────────────────────────────────────────────────────
printf "\n%-3s  %-30s  %-22s  %-70s  %-6s  %-14s  %s\n" \
    "#" "LABEL" "IP" "HOSTNAME" "HTTP" "TIME" "STATUS"
printf '%s\n' "$(printf '─%.0s' {1..175})"

# ─── Evaluate result ──────────────────────────────────────────────────────────
evaluate_result() {
    local http_code="$1"
    local time_total="$2"

    time_total="${time_total%s}"

    local timed_out=false
    if (( $(echo "$time_total >= $CONNECT_TIMEOUT" | bc -l) )); then
        timed_out=true
    fi

    local http_int="${http_code//[^0-9]/}"

    if [[ "$timed_out" == true && "$http_code" == "000" ]]; then
        printf "${RED}TIMEOUT${NC}"
    elif [[ "$http_code" == "000" ]]; then
        printf "${GREEN}OK / NO RESPONSE${NC}"
    elif [[ "$http_int" -ge 500 ]]; then
        printf "${RED}SERVER ERROR${NC}"
    elif [[ "$http_int" -ge 400 ]]; then
        printf "${GREEN}OK / CLIENT ERROR${NC}"
    elif [[ "$timed_out" == true ]]; then
        printf "${RED}TIMEOUT${NC}"
    else
        printf "${GREEN}OK / VALID${NC}"
    fi
}

# ─── Resolve and test ─────────────────────────────────────────────────────────
iX=1
for label in "${ORDER[@]}"; do
    hostnames="${ENTRIES[$label]}"
    first=true

    for hostname in $hostnames; do
        mapfile -t ips < <(dig +short A "$hostname" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

	if [[ ${#ips[@]} -eq 0 ]]; then
            printf "%-3s  %-30s  %-22s  %-70s  %-6s  %-14s  " \
                "$((iX++))" \
                "${first:+$label}" \
                "RESOLVE FAILED" \
                "$hostname" \
                "---" \
                "---"
            printf "${RED}DNS FAILURE${NC}\n"
            first=""
            continue
        fi

        for ip in "${ips[@]}"; do
            # Capture http_code and time_total separately for clean comparison
            raw=$(curl --connect-timeout "$CONNECT_TIMEOUT" -k -s -o /dev/null \
                -w "%{http_code} %{time_total}" "https://${ip}")

            http_code=$(awk '{print $1}' <<< "$raw")
            time_total=$(awk '{print $2}' <<< "$raw")

            # Format time for display
            time_display=$(printf "(%.3fs)" "$time_total")

            status=$(evaluate_result "$http_code" "$time_total")

            printf "%-3s  %-30s  %-22s  %-70s  %-6s  %-14s  " \
                "$((iX++))" \
                "${first:+$label}" \
                "$ip" \
                "$hostname" \
                "$http_code" \
                "$time_display"
            printf "%b\n" "$status"
            first=""
        done
    done

    [[ "$label" == "FD | Package Repository" ]] && echo ""
done
echo ""
