#!/bin/bash

# ================================================
# Custom Command: urlinspect v4 (Syntax Fix)
# Description: Analyzes a URL structure, Domain DNS, IP details (via 1.1.1.1),
#              and provides AI semantic insight.
# Prerequisites: dig, curl, jq, gemini (cli), claude (cli optional)
# ================================================

# --- Formatting Colors ---
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# --- Defaults ---
AI_PROVIDER="gemini"
TargetURL=""

# --- Header Helper ---
header() { echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"; }

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude) AI_PROVIDER="claude"; shift ;;
        http://*|https://*) TargetURL="$1"; shift ;;
        *) echo -e "${RED}Error: Invalid argument or URL format: $1${RESET}"; exit 1 ;;
    esac
done

if [ -z "$TargetURL" ]; then
    echo -e "${RED}Error: Missing URL argument.${RESET}"; exit 1
fi

# --- Prerequisite Check ---
for cmd in dig curl jq "$AI_PROVIDER"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Error: Required command '$cmd' not found in PATH.${RESET}"; exit 1
    fi
done


header "Analyzing Input: $TargetURL"

# ================================================
# PART 1: SPLIT URL STRUCTURE
# ================================================
proto="$(echo "$TargetURL" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
url_no_proto="${TargetURL#"$proto"}"
hostname="$(echo "$url_no_proto" | cut -d/ -f1 | cut -d? -f1 | cut -d: -f1)"
rest_of_url="${url_no_proto#"$hostname"}"

echo -e "${BOLD}Structure Breakdown:${RESET}"
echo -e " [Protocol]   ${proto:-None detected}"
echo -e " [Hostname]   ${YELLOW}$hostname${RESET}"
echo -e " [Path/Query] ${rest_of_url:-/}"


# ================================================
# PART 2: ANALYZE DOMAIN/HOSTNAME (Service Info)
# ================================================
header "Domain & Service Analysis ($hostname)"

cname_record=$(dig +short CNAME "$hostname" | sed 's/\.$//' | tail -n1)

if [ -n "$cname_record" ] && [ "$cname_record" != "$hostname" ]; then
    echo -e " [DNS Type]   CNAME Alias identified."
    echo -e " [Points To]  ${YELLOW}$cname_record${RESET}"

    case "$cname_record" in
        *cloudflare.net*) echo -e " [Hint]       ${CYAN}Service appears to be behind Cloudflare CDN.${RESET}" ;;
        *amazonaws.com*|*cloudfront.net*) echo -e " [Hint]       ${CYAN}Service appears to be hosted on AWS.${RESET}" ;;
        *google*|*appspot.com*) echo -e " [Hint]       ${CYAN}Service appears to be Google Cloud.${RESET}" ;;
        *akamai*|*edgekey.net*) echo -e " [Hint]       ${CYAN}Service appears to be using Akamai CDN.${RESET}" ;;
        *azure*|*trafficmanager.net*) echo -e " [Hint]       ${CYAN}Service appears to be hosted on Azure.${RESET}" ;;
    esac
else
    echo -e " [DNS Type]   Direct A/AAAA record."
fi

# ================================================
# PART 3: ANALYZE IP (Infrastructure & Abuse Info)
# ================================================
target_ip=$(dig @1.1.1.1 +short A "$hostname" | grep -E '^[0-9]' | head -n 1)

if [ -z "$target_ip" ]; then
     header "IP Analysis"
     echo -e "${RED}Could not resolve an IPv4 address via 1.1.1.1.${RESET}"
else
    header "IP Analysis ($target_ip) via 1.1.1.1"

    # Geo/ASN Data
    ip_data=$(curl -s "http://ip-api.com/json/$target_ip?fields=status,country,isp,org,as")
    if [ "$(echo "$ip_data" | jq -r '.status')" == "success" ]; then
        echo -e " [Location]   $(echo "$ip_data" | jq -r '.country')"
        echo -e " [ISP/Org]    ${YELLOW}$(echo "$ip_data" | jq -r '.isp') / $(echo "$ip_data" | jq -r '.org')${RESET}"
        echo -e " [ASN]        $(echo "$ip_data" | jq -r '.as')"
    else
        echo -e "${RED}Failed to query IP information API.${RESET}"
    fi

    # Reputation Check
    rev_ip=$(echo "$target_ip" | awk -F. '{print $4"."$3"."$2"."$1}')
    dnsbl_check=$(dig +short "$rev_ip.zen.spamhaus.org")
    if [ -n "$dnsbl_check" ]; then
        echo -e " [Reputation] ${RED}WARNING: IP listed on Spamhaus Blocklist.${RESET}"
    else
        echo -e " [Reputation] ${GREEN}Clean. IP not listed on Spamhaus Zen DNSBL.${RESET}"
    fi
fi

# ================================================
# PART 4: AI SEMANTIC ANALYSIS
# ================================================
header "AI Semantic Analysis (via $AI_PROVIDER)"

# Build context summary for AI (request JSON output)
ai_context="Analyze this URL and provide security/legitimacy insights.

URL: $TargetURL
Protocol: ${proto:-None}
Hostname: $hostname
Path/Query: ${rest_of_url:-/}
CNAME: ${cname_record:-None (Direct A record)}
Resolved IP: ${target_ip:-Unresolved}
Location: $(echo "$ip_data" 2>/dev/null | jq -r '.country // "Unknown"')
ISP/Org: $(echo "$ip_data" 2>/dev/null | jq -r '.isp // "Unknown"') / $(echo "$ip_data" 2>/dev/null | jq -r '.org // "Unknown"')
ASN: $(echo "$ip_data" 2>/dev/null | jq -r '.as // "Unknown"')
Blocklist Status: $([ -n "$dnsbl_check" ] && echo "LISTED on Spamhaus" || echo "Clean")

Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  \"legitimacy\": \"<domain legitimacy assessment: brand, typosquatting, suspicious patterns>\",
  \"infrastructure\": \"<infrastructure trust signals: hosting provider reputation, CDN usage>\",
  \"path_risk\": \"<URL path/query risk indicators or 'None detected'>\",
  \"risk_rating\": \"<Low|Medium|High>\",
  \"reasoning\": \"<brief reasoning for the risk rating>\"
}"

# Execute AI analysis based on provider (JSON output mode)
if [ "$AI_PROVIDER" == "gemini" ]; then
    ai_raw=$(echo "$ai_context" | gemini 2>/dev/null)
elif [ "$AI_PROVIDER" == "claude" ]; then
    ai_raw=$(echo "$ai_context" | claude --print --output-format json 2>/dev/null | jq -r '.result // .')
fi

# Parse JSON response with jq
if echo "$ai_raw" | jq empty 2>/dev/null; then
    legitimacy=$(echo "$ai_raw" | jq -r '.legitimacy // "N/A"')
    infrastructure=$(echo "$ai_raw" | jq -r '.infrastructure // "N/A"')
    path_risk=$(echo "$ai_raw" | jq -r '.path_risk // "N/A"')
    risk_rating=$(echo "$ai_raw" | jq -r '.risk_rating // "Unknown"')
    reasoning=$(echo "$ai_raw" | jq -r '.reasoning // "N/A"')

    # Color-code risk rating
    case "$risk_rating" in
        Low)    risk_color="${GREEN}" ;;
        Medium) risk_color="${YELLOW}" ;;
        High)   risk_color="${RED}" ;;
        *)      risk_color="${RESET}" ;;
    esac

    echo -e " [Legitimacy]     $legitimacy"
    echo -e " [Infrastructure] $infrastructure"
    echo -e " [Path Risk]      $path_risk"
    echo -e " [Risk Rating]    ${risk_color}${BOLD}$risk_rating${RESET}"
    echo -e " [Reasoning]      $reasoning"
else
    echo -e "${RED}AI analysis failed to return valid JSON.${RESET}"
    echo -e "${YELLOW}Raw response: $ai_raw${RESET}"
fi

echo -e "\n${BOLD}${GREEN}Analysis Complete.${RESET}"
