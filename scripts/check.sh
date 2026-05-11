#!/usr/bin/env bash

REPORT="report.md"

DOMAINS=(
  "api.sd-rtn.com"
  "api.agora.io"
  "api-ap-southeast-1.sd-rtn.com"
  "api-ap-southeast-1.agora.io"
  "api-ap-northeast-1.sd-rtn.com"
  "api-ap-northeast-1.agora.io"
)

GULF_REGIONS=(
  "Saudi Arabia"
  "United Arab Emirates"
  "Qatar"
  "Kuwait"
  "Bahrain"
)

# ─── Init report ──────────────────────────────────────────────────────────────
{
  echo "# Agora Gulf Connectivity Diagnostic Report"
  echo ""
  echo "**Generated:** $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo ""
  echo "**Purpose:** Identify DNS failures, TCP blocks, TLS issues, or routing anomalies"
  echo "affecting Gulf-region users joining Agora-powered video classes."
  echo ""
  echo "---"
  echo ""
  echo "## Legend"
  echo ""
  echo "| Section | Tool | What it reveals |"
  echo "|---------|------|-----------------|"
  echo "| Local DNS | \`dig\` | IP the GitHub runner resolves |"
  echo "| Local DNS (alt) | \`nslookup\` | Cross-check using system resolver |"
  echo "| TLS/HTTPS | \`openssl s_client\` | Certificate validity, TLS handshake |"
  echo "| HTTP Status | \`curl\` | HTTP response code and headers |"
  echo "| Port Scan | \`nmap\` | Whether ports 80/443/4000-4500 are open |"
  echo "| Local Ping | \`ping\` | Packet loss and latency from runner |"
  echo "| Local Traceroute | \`traceroute\` | Routing path from runner |"
  echo "| Gulf DNS | Globalping | DNS resolution from Gulf ISPs |"
  echo "| Gulf HTTP | Globalping | HTTP reachability from Gulf ISPs |"
  echo "| Gulf Ping | Globalping | Latency and loss from Gulf ISPs |"
  echo "| Gulf Traceroute | Globalping | Routing path through Gulf networks |"
  echo "| Gulf MTR | Globalping | Combined ping+traceroute from Gulf |"
  echo ""
  echo "---"
  echo ""
} >"$REPORT"


# ─── Section 1: Local checks (from GitHub runner) ────────────────────────────
{
  echo "## Part 1 — Local Checks (from GitHub Actions runner)"
  echo ""
  echo "> These run directly on the Ubuntu runner. Useful as a baseline."
  echo ""
} >>"$REPORT"

for domain in "${DOMAINS[@]}"; do
  {
    echo "### \`${domain}\`"
    echo ""

    # --- dig
    echo "#### DNS — dig"
    echo '```'
    dig +nocmd +noall +answer +ttlid A "$domain" 2>&1 || true
    dig +nocmd +noall +answer +ttlid AAAA "$domain" 2>&1 || true
    echo '```'
    echo ""

    # --- nslookup
    echo "#### DNS — nslookup"
    echo '```'
    nslookup "$domain" 2>&1 || true
    echo '```'
    echo ""

    # --- openssl TLS
    echo "#### TLS Certificate — openssl s_client"
    echo '```'
    echo "" | timeout 8 openssl s_client -connect "${domain}:443" -servername "$domain" 2>&1 | \
      grep -E "subject=|issuer=|SSL-Session:|Protocol|Cipher|Verify|CONNECTED|FAILED|error" || true
    echo '```'
    echo ""

    # --- curl HTTP
    echo "#### HTTP Response — curl"
    echo '```'
    curl -sv --max-time 10 --connect-timeout 6 -o /dev/null \
      "https://${domain}" 2>&1 | grep -E "^\*|^>|^<|curl:" | head -40 || true
    echo '```'
    echo ""

    # --- nmap ports
    echo "#### Port Scan — nmap (80, 443, 4000-4010)"
    echo '```'
    nmap -T4 --open -p 80,443,4000-4010 "$domain" 2>&1 || true
    echo '```'
    echo ""

    # --- ping
    echo "#### Ping — local"
    echo '```'
    ping -c 4 -W 5 "$domain" 2>&1 || true
    echo '```'
    echo ""

    # --- traceroute
    echo "#### Traceroute — local"
    echo '```'
    traceroute -m 20 -w 3 "$domain" 2>&1 || true
    echo '```'
    echo ""

    echo "---"
    echo ""
  } >>"$REPORT"
done


# ─── Section 2: Gulf-region checks via Globalping ────────────────────────────
{
  echo "## Part 2 — Gulf Region Checks (via Globalping probe network)"
  echo ""
  echo "> These run from real ISP probes inside Gulf countries."
  echo "> NXDOMAIN on DNS or timeout on ping from these locations = confirmed block."
  echo ""
} >>"$REPORT"

for domain in "${DOMAINS[@]}"; do
  for region in "${GULF_REGIONS[@]}"; do
    {
      echo "### \`${domain}\` — ${region}"
      echo ""

      # --- Globalping DNS
      echo "#### DNS Lookup"
      echo '```'
      globalping dns "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 3

    {
      # --- Globalping HTTP
      echo "#### HTTP Probe"
      echo '```'
      globalping http "$domain" from "$region" --limit 1 --method head --full --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 3

    {
      # --- Globalping Ping
      echo "#### Ping"
      echo '```'
      globalping ping "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 3

    {
      # --- Globalping Traceroute
      echo "#### Traceroute"
      echo '```'
      globalping traceroute "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""

      # --- Globalping MTR
      echo "#### MTR (ping + traceroute combined)"
      echo '```'
      globalping mtr "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""

      echo "---"
      echo ""
    } >>"$REPORT"
    sleep 3
  done
done

# ─── Footer ──────────────────────────────────────────────────────────────────
{
  echo ""
  echo "## Report Complete"
  echo ""
  echo "**Finished:** $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo ""
  echo "### How to read results"
  echo ""
  echo "- **DNS returns NXDOMAIN from Gulf** → domain blocked at DNS level by ISP"
  echo "- **DNS resolves but ping times out from Gulf** → ICMP blocked, try HTTP check"  
  echo "- **HTTP 403 or TCP timeout from Gulf** → firewall or DPI blocking HTTPS"
  echo "- **Traceroute stops at a Gulf hop** → ISP or national gateway is dropping packets"
  echo "- **TLS handshake fails** → certificate issue or SN