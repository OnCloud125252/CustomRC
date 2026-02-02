#!/bin/bash

# ================================================
# Custom Command: urlinspect v5 (Enhanced Analytics)
# Description: Comprehensive URL security and infrastructure analysis
#              with DNS, SSL, HTTP headers, WHOIS, and AI insights.
# Prerequisites: dig, curl, jq, openssl, whois (optional)
#                gemini (cli) or claude (cli) for AI analysis
# ================================================

# --- Formatting Colors ---
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
BLUE="\033[0;34m"
WHITE="\033[1;37m"
RESET="\033[0m"

# --- Box Drawing Characters ---
BOX_TL="╭"
BOX_TR="╮"
BOX_BL="╰"
BOX_BR="╯"
BOX_H="─"
BOX_V="│"
BOX_SEP="├"
BOX_END="┤"

# --- Defaults ---
AI_PROVIDER="gemini"
TargetURL=""
VERBOSE=false
SKIP_AI=false
TIMEOUT=10

# --- Helper Functions ---
repeat_char() {
    local char="$1" count="$2"
    printf "%${count}s" | tr ' ' "$char"
}

box_header() {
    local title="$1"
    local width=60
    local title_len=${#title}
    local padding=$(( (width - title_len - 4) / 2 ))

    echo ""
    echo -e "${CYAN}${BOX_TL}$(repeat_char "$BOX_H" $padding) ${BOLD}$title${RESET}${CYAN} $(repeat_char "$BOX_H" $padding)${BOX_TR}${RESET}"
}

box_line() {
    local label="$1" value="$2" color="${3:-$RESET}"
    printf "${CYAN}${BOX_V}${RESET} ${DIM}%-14s${RESET} ${color}%s${RESET}\n" "$label" "$value"
}

box_footer() {
    echo -e "${CYAN}${BOX_BL}$(repeat_char "$BOX_H" 60)${BOX_BR}${RESET}"
}

spinner() {
    local pid=$1 msg="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${DIM}${spin:i++%${#spin}:1} %s${RESET}" "$msg"
        sleep 0.1
    done
    printf "\r%-50s\r" " "
}

check_command() {
    command -v "$1" &> /dev/null
}

# --- Usage ---
usage() {
    echo -e "${BOLD}Usage:${RESET} urlinspect [OPTIONS] <URL>"
    echo ""
    echo -e "${BOLD}Options:${RESET}"
    echo "  --claude       Use Claude CLI for AI analysis (default: gemini)"
    echo "  --skip-ai      Skip AI semantic analysis"
    echo "  --verbose      Show detailed output"
    echo "  --help         Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${RESET}"
    echo "  urlinspect https://example.com"
    echo "  urlinspect --claude https://suspicious-site.xyz/login"
    echo "  urlinspect --skip-ai https://api.service.com/v1/users"
    exit 0
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --claude) AI_PROVIDER="claude"; shift ;;
        --skip-ai) SKIP_AI=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --help|-h) usage ;;
        http://*|https://*) TargetURL="$1"; shift ;;
        *) echo -e "${RED}Error: Invalid argument: $1${RESET}"; echo "Use --help for usage."; exit 1 ;;
    esac
done

if [ -z "$TargetURL" ]; then
    echo -e "${RED}Error: Missing URL argument.${RESET}"
    echo "Use --help for usage."
    exit 1
fi

# --- Prerequisite Check ---
REQUIRED_CMDS=(dig curl jq openssl)
MISSING_CMDS=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! check_command "$cmd"; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required commands: ${MISSING_CMDS[*]}${RESET}"
    exit 1
fi

if [ "$SKIP_AI" = false ] && ! check_command "$AI_PROVIDER"; then
    echo -e "${YELLOW}Warning: AI provider '$AI_PROVIDER' not found. Skipping AI analysis.${RESET}"
    SKIP_AI=true
fi

# --- Banner ---
echo ""
echo -e "${BOLD}${CYAN}  ╦ ╦╦═╗╦  ╦╔╗╔╔═╗╔═╗╔═╗╔═╗╔╦╗${RESET}"
echo -e "${BOLD}${CYAN}  ║ ║╠╦╝║  ║║║║╚═╗╠═╝║╣ ║   ║ ${RESET}"
echo -e "${BOLD}${CYAN}  ╚═╝╩╚═╩═╝╩╝╚╝╚═╝╩  ╚═╝╚═╝ ╩ ${RESET} ${DIM}v5.0${RESET}"
echo ""
echo -e "${DIM}Target: ${RESET}${BOLD}$TargetURL${RESET}"

# ================================================
# PART 1: URL STRUCTURE PARSING
# ================================================
box_header "URL Structure"

proto="$(echo "$TargetURL" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
url_no_proto="${TargetURL#"$proto"}"
hostname="$(echo "$url_no_proto" | cut -d/ -f1 | cut -d? -f1 | cut -d: -f1)"
port="$(echo "$url_no_proto" | cut -d/ -f1 | grep : | cut -d: -f2)"
rest_of_url="${url_no_proto#"$hostname"}"
[ -n "$port" ] && rest_of_url="${rest_of_url#":$port"}"

# Extract path and query separately
path="$(echo "$rest_of_url" | cut -d? -f1)"
query="$(echo "$rest_of_url" | grep '?' | cut -d? -f2-)"

box_line "Protocol" "${proto:-None detected}" "$YELLOW"
box_line "Hostname" "$hostname" "$WHITE"
[ -n "$port" ] && box_line "Port" "$port" "$YELLOW"
box_line "Path" "${path:-/}" "$RESET"
[ -n "$query" ] && box_line "Query" "$query" "$DIM"

# Analyze URL path for suspicious patterns
suspicious_patterns=()
[[ "$rest_of_url" =~ \.\. ]] && suspicious_patterns+=("path traversal (..)")
[[ "$rest_of_url" =~ (login|signin|account|password|verify|secure|update|confirm) ]] && suspicious_patterns+=("auth-related keywords")
[[ "$rest_of_url" =~ (\<|\>|script|javascript:) ]] && suspicious_patterns+=("potential XSS")
[[ "$rest_of_url" =~ (base64|eval\(|exec\() ]] && suspicious_patterns+=("encoded/executable content")
[[ "$hostname" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && suspicious_patterns+=("IP-based hostname")

if [ ${#suspicious_patterns[@]} -gt 0 ]; then
    box_line "⚠ Patterns" "${suspicious_patterns[*]}" "$RED"
fi

box_footer

# ================================================
# PART 2: DNS ANALYSIS
# ================================================
box_header "DNS Analysis"

# A Records
a_records=$(dig @1.1.1.1 +short A "$hostname" 2>/dev/null | grep -E '^[0-9]')
target_ip=$(echo "$a_records" | head -n 1)

if [ -n "$a_records" ]; then
    a_count=$(echo "$a_records" | wc -l | tr -d ' ')
    box_line "A Records" "$a_count found" "$GREEN"
    echo "$a_records" | while read -r ip; do
        echo -e "${CYAN}${BOX_V}${RESET}   └─ ${YELLOW}$ip${RESET}"
    done
else
    box_line "A Records" "None found" "$RED"
fi

# AAAA Records
aaaa_records=$(dig @1.1.1.1 +short AAAA "$hostname" 2>/dev/null | head -n 3)
if [ -n "$aaaa_records" ]; then
    box_line "AAAA Records" "IPv6 enabled" "$GREEN"
fi

# CNAME Records
cname_record=$(dig +short CNAME "$hostname" 2>/dev/null | sed 's/\.$//' | tail -n1)

if [ -n "$cname_record" ] && [ "$cname_record" != "$hostname" ]; then
    box_line "CNAME" "$cname_record" "$YELLOW"

    # Detect service from CNAME
    service_hint=""
    case "$cname_record" in
        *cloudflare.net*|*cloudflare-dns.com*) service_hint="Cloudflare CDN/Proxy" ;;
        *amazonaws.com*|*cloudfront.net*|*elasticbeanstalk.com*) service_hint="AWS" ;;
        *google*|*appspot.com*|*googleapis.com*) service_hint="Google Cloud" ;;
        *akamai*|*edgekey.net*|*edgesuite.net*) service_hint="Akamai CDN" ;;
        *azure*|*trafficmanager.net*|*azurewebsites.net*) service_hint="Microsoft Azure" ;;
        *fastly*) service_hint="Fastly CDN" ;;
        *github.io*|*githubusercontent.com*) service_hint="GitHub Pages" ;;
        *vercel*|*now.sh*) service_hint="Vercel" ;;
        *netlify*) service_hint="Netlify" ;;
        *shopify*) service_hint="Shopify" ;;
    esac

    [ -n "$service_hint" ] && box_line "Service" "$service_hint" "$CYAN"
else
    box_line "CNAME" "Direct A record (no alias)" "$DIM"
fi

# MX Records (email capability)
mx_records=$(dig +short MX "$hostname" 2>/dev/null | head -n 3)
if [ -n "$mx_records" ]; then
    mx_provider=""
    case "$mx_records" in
        *google*|*gmail*) mx_provider="Google Workspace" ;;
        *outlook*|*microsoft*) mx_provider="Microsoft 365" ;;
        *zoho*) mx_provider="Zoho Mail" ;;
        *proton*) mx_provider="ProtonMail" ;;
    esac
    box_line "MX Records" "${mx_provider:-Custom mail server}" "$GREEN"
fi

# TXT Records (SPF/DMARC)
txt_records=$(dig +short TXT "$hostname" 2>/dev/null)
if echo "$txt_records" | grep -q "v=spf"; then
    box_line "SPF" "Configured" "$GREEN"
else
    box_line "SPF" "Not found" "$YELLOW"
fi

dmarc_record=$(dig +short TXT "_dmarc.$hostname" 2>/dev/null)
if [ -n "$dmarc_record" ]; then
    box_line "DMARC" "Configured" "$GREEN"
else
    box_line "DMARC" "Not found" "$YELLOW"
fi

box_footer

# ================================================
# PART 3: IP & GEOLOCATION ANALYSIS
# ================================================
if [ -n "$target_ip" ]; then
    box_header "IP Intelligence ($target_ip)"

    # Geo/ASN Data
    ip_data=$(curl -s --max-time $TIMEOUT "http://ip-api.com/json/$target_ip?fields=status,country,countryCode,city,isp,org,as,hosting")

    if [ "$(echo "$ip_data" | jq -r '.status')" == "success" ]; then
        country=$(echo "$ip_data" | jq -r '.country // "Unknown"')
        country_code=$(echo "$ip_data" | jq -r '.countryCode // ""')
        city=$(echo "$ip_data" | jq -r '.city // ""')
        isp=$(echo "$ip_data" | jq -r '.isp // "Unknown"')
        org=$(echo "$ip_data" | jq -r '.org // "Unknown"')
        asn=$(echo "$ip_data" | jq -r '.as // "Unknown"')
        is_hosting=$(echo "$ip_data" | jq -r '.hosting // false')

        location="$country"
        [ -n "$city" ] && location="$city, $country"

        box_line "Location" "$location" "$RESET"
        box_line "ISP" "$isp" "$YELLOW"
        box_line "Organization" "$org" "$RESET"
        box_line "ASN" "$asn" "$DIM"

        if [ "$is_hosting" = "true" ]; then
            box_line "Type" "Hosting/Data Center" "$CYAN"
        fi
    else
        box_line "Status" "IP lookup failed" "$RED"
    fi

    # Blocklist Checks
    echo -e "${CYAN}${BOX_SEP}$(repeat_char "$BOX_H" 15) ${DIM}Reputation${RESET} $(repeat_char "$BOX_H" 15)${BOX_END}${RESET}"

    rev_ip=$(echo "$target_ip" | awk -F. '{print $4"."$3"."$2"."$1}')
    blocklist_hits=0

    # Spamhaus ZEN
    if dig +short "$rev_ip.zen.spamhaus.org" 2>/dev/null | grep -q '^127\.'; then
        box_line "Spamhaus ZEN" "LISTED ⚠" "$RED"
        ((blocklist_hits++))
    else
        box_line "Spamhaus ZEN" "Clean" "$GREEN"
    fi

    # Spamhaus CSS (for hosting IPs)
    if dig +short "$rev_ip.css.spamhaus.org" 2>/dev/null | grep -q '^127\.'; then
        box_line "Spamhaus CSS" "LISTED ⚠" "$RED"
        ((blocklist_hits++))
    fi

    # Barracuda
    if dig +short "$rev_ip.b.barracudacentral.org" 2>/dev/null | grep -q '^127\.'; then
        box_line "Barracuda" "LISTED ⚠" "$RED"
        ((blocklist_hits++))
    else
        [ "$VERBOSE" = true ] && box_line "Barracuda" "Clean" "$GREEN"
    fi

    # SORBS
    if dig +short "$rev_ip.dnsbl.sorbs.net" 2>/dev/null | grep -q '^127\.'; then
        box_line "SORBS" "LISTED ⚠" "$RED"
        ((blocklist_hits++))
    else
        [ "$VERBOSE" = true ] && box_line "SORBS" "Clean" "$GREEN"
    fi

    if [ $blocklist_hits -eq 0 ]; then
        box_line "Overall" "No blocklist hits ✓" "$GREEN"
    else
        box_line "Overall" "$blocklist_hits blocklist(s) flagged" "$RED"
    fi

    box_footer
else
    box_header "IP Intelligence"
    box_line "Status" "Could not resolve IPv4 address" "$RED"
    box_footer
fi

# ================================================
# PART 4: SSL/TLS CERTIFICATE ANALYSIS
# ================================================
if [[ "$proto" == "https://" ]]; then
    box_header "TLS Certificate"

    ssl_port="${port:-443}"
    cert_data=$(echo | timeout $TIMEOUT openssl s_client -servername "$hostname" -connect "$hostname:$ssl_port" 2>/dev/null)

    if [ -n "$cert_data" ]; then
        # Extract certificate details
        cert_info=$(echo "$cert_data" | openssl x509 -noout -subject -issuer -dates -ext subjectAltName 2>/dev/null)

        if [ -n "$cert_info" ]; then
            # Subject (CN)
            subject=$(echo "$cert_info" | grep "subject=" | sed 's/subject=//' | sed 's/.*CN = //' | cut -d',' -f1)
            box_line "Subject" "${subject:-N/A}" "$WHITE"

            # Issuer
            issuer=$(echo "$cert_info" | grep "issuer=" | sed 's/issuer=//' | sed 's/.*O = //' | cut -d',' -f1)
            box_line "Issuer" "${issuer:-N/A}" "$RESET"

            # Validity
            not_before=$(echo "$cert_info" | grep "notBefore=" | sed 's/notBefore=//')
            not_after=$(echo "$cert_info" | grep "notAfter=" | sed 's/notAfter=//')

            if [ -n "$not_after" ]; then
                # Check if expired
                expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$not_after" "+%s" 2>/dev/null || date -d "$not_after" "+%s" 2>/dev/null)
                current_epoch=$(date "+%s")

                if [ -n "$expiry_epoch" ]; then
                    days_left=$(( (expiry_epoch - current_epoch) / 86400 ))

                    if [ $days_left -lt 0 ]; then
                        box_line "Expiry" "EXPIRED ${days_left#-} days ago" "$RED"
                    elif [ $days_left -lt 30 ]; then
                        box_line "Expiry" "$days_left days remaining ⚠" "$YELLOW"
                    else
                        box_line "Expiry" "$days_left days remaining" "$GREEN"
                    fi
                else
                    box_line "Valid Until" "$not_after" "$RESET"
                fi
            fi

            # Certificate chain verification
            verify_result=$(echo "$cert_data" | grep "Verify return code" | sed 's/.*: //')
            if [[ "$verify_result" == "0 (ok)" ]]; then
                box_line "Chain" "Valid ✓" "$GREEN"
            else
                box_line "Chain" "${verify_result:-Unknown}" "$YELLOW"
            fi

            # TLS Version
            tls_version=$(echo "$cert_data" | grep "Protocol" | head -n1 | awk '{print $NF}')
            if [ -n "$tls_version" ]; then
                case "$tls_version" in
                    TLSv1.3) box_line "TLS Version" "$tls_version" "$GREEN" ;;
                    TLSv1.2) box_line "TLS Version" "$tls_version" "$YELLOW" ;;
                    *) box_line "TLS Version" "$tls_version" "$RED" ;;
                esac
            fi
        else
            box_line "Status" "Could not parse certificate" "$YELLOW"
        fi
    else
        box_line "Status" "TLS connection failed" "$RED"
    fi

    box_footer
fi

# ================================================
# PART 5: HTTP HEADERS SECURITY ANALYSIS
# ================================================
box_header "HTTP Security Headers"

http_response=$(curl -s -I --max-time $TIMEOUT -L "$TargetURL" 2>/dev/null | head -n 50)

if [ -n "$http_response" ]; then
    # HTTP Status
    http_status=$(echo "$http_response" | grep -i "^HTTP/" | tail -n1 | awk '{print $2}')
    case "$http_status" in
        200|301|302|304) box_line "Status" "$http_status OK" "$GREEN" ;;
        4*) box_line "Status" "$http_status Client Error" "$YELLOW" ;;
        5*) box_line "Status" "$http_status Server Error" "$RED" ;;
        *) box_line "Status" "${http_status:-Unknown}" "$DIM" ;;
    esac

    # Server header
    server=$(echo "$http_response" | grep -i "^Server:" | head -n1 | sed 's/Server: //i' | tr -d '\r')
    [ -n "$server" ] && box_line "Server" "$server" "$DIM"

    # Security headers check
    headers_score=0
    headers_max=6

    # Strict-Transport-Security
    if echo "$http_response" | grep -qi "strict-transport-security"; then
        box_line "HSTS" "Present ✓" "$GREEN"
        ((headers_score++))
    else
        box_line "HSTS" "Missing" "$YELLOW"
    fi

    # Content-Security-Policy
    if echo "$http_response" | grep -qi "content-security-policy"; then
        box_line "CSP" "Present ✓" "$GREEN"
        ((headers_score++))
    else
        box_line "CSP" "Missing" "$YELLOW"
    fi

    # X-Frame-Options
    if echo "$http_response" | grep -qi "x-frame-options"; then
        box_line "X-Frame-Opt" "Present ✓" "$GREEN"
        ((headers_score++))
    else
        box_line "X-Frame-Opt" "Missing" "$YELLOW"
    fi

    # X-Content-Type-Options
    if echo "$http_response" | grep -qi "x-content-type-options"; then
        box_line "X-Content-Type" "Present ✓" "$GREEN"
        ((headers_score++))
    else
        [ "$VERBOSE" = true ] && box_line "X-Content-Type" "Missing" "$YELLOW"
    fi

    # X-XSS-Protection (deprecated but still checked)
    if echo "$http_response" | grep -qi "x-xss-protection"; then
        ((headers_score++))
    fi

    # Referrer-Policy
    if echo "$http_response" | grep -qi "referrer-policy"; then
        ((headers_score++))
    fi

    # Score summary
    if [ $headers_score -ge 4 ]; then
        box_line "Score" "$headers_score/$headers_max (Good)" "$GREEN"
    elif [ $headers_score -ge 2 ]; then
        box_line "Score" "$headers_score/$headers_max (Fair)" "$YELLOW"
    else
        box_line "Score" "$headers_score/$headers_max (Poor)" "$RED"
    fi
else
    box_line "Status" "Could not fetch headers" "$RED"
fi

box_footer

# ================================================
# PART 6: WHOIS DOMAIN ANALYSIS (Optional)
# ================================================
if check_command whois; then
    box_header "WHOIS Information"

    # Extract base domain (simple approach)
    base_domain=$(echo "$hostname" | awk -F. '{if (NF>=2) print $(NF-1)"."$NF; else print $0}')

    whois_data=$(timeout $TIMEOUT whois "$base_domain" 2>/dev/null)

    if [ -n "$whois_data" ]; then
        # Creation date
        creation=$(echo "$whois_data" | grep -i "creation date\|created\|registration time" | head -n1 | sed 's/.*: *//')
        if [ -n "$creation" ]; then
            # Try to calculate domain age
            creation_year=$(echo "$creation" | grep -oE '^[0-9]{4}')
            current_year=$(date +%Y)
            if [ -n "$creation_year" ]; then
                domain_age=$((current_year - creation_year))
                if [ $domain_age -lt 1 ]; then
                    box_line "Created" "$creation (New domain ⚠)" "$YELLOW"
                else
                    box_line "Created" "$creation (~${domain_age} years)" "$GREEN"
                fi
            else
                box_line "Created" "$creation" "$RESET"
            fi
        fi

        # Registrar
        registrar=$(echo "$whois_data" | grep -i "registrar:" | head -n1 | sed 's/.*: *//')
        [ -n "$registrar" ] && box_line "Registrar" "$registrar" "$DIM"

        # Name servers
        ns_count=$(echo "$whois_data" | grep -ci "name server")
        [ $ns_count -gt 0 ] && box_line "Name Servers" "$ns_count configured" "$GREEN"

        # DNSSEC
        if echo "$whois_data" | grep -qi "dnssec.*signed\|dnssec.*yes"; then
            box_line "DNSSEC" "Enabled ✓" "$GREEN"
        else
            box_line "DNSSEC" "Not enabled" "$DIM"
        fi
    else
        box_line "Status" "WHOIS lookup failed" "$YELLOW"
    fi

    box_footer
fi

# ================================================
# PART 7: REDIRECT CHAIN ANALYSIS
# ================================================
box_header "Redirect Analysis"

redirect_chain=$(curl -s --max-time $TIMEOUT -L -w "%{url_effective}\n" -o /dev/null "$TargetURL" 2>/dev/null)
redirect_count=$(curl -s --max-time $TIMEOUT -L -w "%{redirect_count}" -o /dev/null "$TargetURL" 2>/dev/null)

if [ -n "$redirect_count" ] && [ "$redirect_count" -gt 0 ]; then
    box_line "Redirects" "$redirect_count hops" "$YELLOW"
    box_line "Final URL" "$redirect_chain" "$RESET"

    # Check if final domain differs
    final_hostname=$(echo "$redirect_chain" | sed -e 's,^.*://,,' | cut -d/ -f1 | cut -d: -f1)
    if [ "$final_hostname" != "$hostname" ]; then
        box_line "⚠ Notice" "Redirects to different domain" "$YELLOW"
    fi
else
    box_line "Redirects" "None (direct access)" "$GREEN"
fi

box_footer

# ================================================
# PART 8: AI SEMANTIC ANALYSIS
# ================================================
if [ "$SKIP_AI" = false ]; then
    box_header "AI Security Analysis ($AI_PROVIDER)"

    # Build comprehensive context for AI
    ai_context="Analyze this URL for security and legitimacy. Provide a security assessment.

URL: $TargetURL
Protocol: ${proto:-None}
Hostname: $hostname
Path/Query: ${rest_of_url:-/}
CNAME: ${cname_record:-Direct A record}
Resolved IP: ${target_ip:-Unresolved}
Location: $(echo "$ip_data" 2>/dev/null | jq -r '.country // "Unknown"')
ISP/Org: $(echo "$ip_data" 2>/dev/null | jq -r '.isp // "Unknown"') / $(echo "$ip_data" 2>/dev/null | jq -r '.org // "Unknown"')
ASN: $(echo "$ip_data" 2>/dev/null | jq -r '.as // "Unknown"')
Hosting: $(echo "$ip_data" 2>/dev/null | jq -r '.hosting // "Unknown"')
Blocklist Hits: $blocklist_hits
HTTP Status: ${http_status:-Unknown}
Security Headers Score: ${headers_score:-0}/${headers_max:-6}
Domain Age: ${domain_age:-Unknown} years
Redirect Count: ${redirect_count:-0}

Suspicious URL Patterns Found: ${suspicious_patterns[*]:-None}

Respond ONLY with valid JSON (no markdown, no code blocks):
{
  \"legitimacy\": \"<brand recognition, typosquatting analysis, domain reputation>\",
  \"infrastructure\": \"<hosting provider trust, CDN usage, TLS quality>\",
  \"path_risk\": \"<URL path/query risk indicators>\",
  \"risk_rating\": \"<Low|Medium|High|Critical>\",
  \"confidence\": \"<Low|Medium|High>\",
  \"key_concerns\": [\"<concern1>\", \"<concern2>\"],
  \"reasoning\": \"<2-3 sentence explanation>\"
}"

    # Execute AI analysis
    if [ "$AI_PROVIDER" == "gemini" ]; then
        ai_raw=$(echo "$ai_context" | gemini 2>/dev/null)
    elif [ "$AI_PROVIDER" == "claude" ]; then
        ai_raw=$(echo "$ai_context" | claude --print --output-format json 2>/dev/null | jq -r '.result // .')
    fi

    # Parse JSON response
    if echo "$ai_raw" | jq empty 2>/dev/null; then
        legitimacy=$(echo "$ai_raw" | jq -r '.legitimacy // "N/A"')
        infrastructure=$(echo "$ai_raw" | jq -r '.infrastructure // "N/A"')
        path_risk=$(echo "$ai_raw" | jq -r '.path_risk // "N/A"')
        risk_rating=$(echo "$ai_raw" | jq -r '.risk_rating // "Unknown"')
        confidence=$(echo "$ai_raw" | jq -r '.confidence // "N/A"')
        reasoning=$(echo "$ai_raw" | jq -r '.reasoning // "N/A"')

        # Key concerns as array
        concerns=$(echo "$ai_raw" | jq -r '.key_concerns // [] | .[]' 2>/dev/null)

        # Color-code risk rating
        case "$risk_rating" in
            Low)      risk_color="${GREEN}" ;;
            Medium)   risk_color="${YELLOW}" ;;
            High)     risk_color="${RED}" ;;
            Critical) risk_color="${BOLD}${RED}" ;;
            *)        risk_color="${RESET}" ;;
        esac

        box_line "Legitimacy" "$legitimacy" "$RESET"
        box_line "Infrastructure" "$infrastructure" "$RESET"
        box_line "Path Risk" "$path_risk" "$RESET"

        if [ -n "$concerns" ]; then
            echo -e "${CYAN}${BOX_SEP}$(repeat_char "$BOX_H" 15) ${DIM}Concerns${RESET} $(repeat_char "$BOX_H" 17)${BOX_END}${RESET}"
            echo "$concerns" | while read -r concern; do
                echo -e "${CYAN}${BOX_V}${RESET}   ${RED}• $concern${RESET}"
            done
        fi

        echo -e "${CYAN}${BOX_SEP}$(repeat_char "$BOX_H" 15) ${DIM}Assessment${RESET} $(repeat_char "$BOX_H" 15)${BOX_END}${RESET}"
        box_line "Risk Rating" "$risk_rating" "$risk_color"
        box_line "Confidence" "$confidence" "$DIM"
        box_line "Reasoning" "$reasoning" "$RESET"
    else
        box_line "Status" "AI analysis returned invalid JSON" "$RED"
        [ "$VERBOSE" = true ] && echo -e "${DIM}$ai_raw${RESET}"
    fi

    box_footer
fi

# ================================================
# SUMMARY
# ================================================
echo ""
echo -e "${CYAN}${BOX_TL}$(repeat_char "$BOX_H" 20) ${BOLD}Summary${RESET} ${CYAN}$(repeat_char "$BOX_H" 20)${BOX_TR}${RESET}"

# Calculate overall risk indicators
risk_indicators=0
[ ${#suspicious_patterns[@]} -gt 0 ] && ((risk_indicators++))
[ "$blocklist_hits" -gt 0 ] && ((risk_indicators++))
[ "${headers_score:-0}" -lt 3 ] && ((risk_indicators++))
[ "${domain_age:-10}" -lt 1 ] && ((risk_indicators++))
[ "${redirect_count:-0}" -gt 3 ] && ((risk_indicators++))

if [ $risk_indicators -eq 0 ]; then
    echo -e "${CYAN}${BOX_V}${RESET}  ${GREEN}${BOLD}✓ No major security concerns detected${RESET}"
elif [ $risk_indicators -lt 3 ]; then
    echo -e "${CYAN}${BOX_V}${RESET}  ${YELLOW}${BOLD}⚠ $risk_indicators potential concern(s) found${RESET}"
else
    echo -e "${CYAN}${BOX_V}${RESET}  ${RED}${BOLD}⚠ $risk_indicators risk indicator(s) detected - exercise caution${RESET}"
fi

echo -e "${CYAN}${BOX_V}${RESET}"
echo -e "${CYAN}${BOX_V}${RESET}  ${DIM}Analyzed: $hostname${RESET}"
echo -e "${CYAN}${BOX_V}${RESET}  ${DIM}IP: ${target_ip:-Unresolved} | Headers: ${headers_score:-?}/${headers_max:-6} | Blocklists: $blocklist_hits${RESET}"
echo -e "${CYAN}${BOX_BL}$(repeat_char "$BOX_H" 50)${BOX_BR}${RESET}"
echo ""
