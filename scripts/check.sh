#!/usr/bin/env bash

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

REPORT="report.md"

# Initialize report
echo "# Agora Gulf Connectivity Report" > "$REPORT"
echo "" >> "$REPORT"
echo "Generated on: $(date)" >> "$REPORT"
echo "" >> "$REPORT"

# PART 1 — Local baseline tests
echo "## Local Baseline Tests (GitHub Ubuntu Runner)" >> "$REPORT"
echo "" >> "$REPORT"

for domain in "${DOMAINS[@]}"; do
  echo "### $domain" >> "$REPORT"
  echo "" >> "$REPORT"

  echo "#### DNS — dig (A record)" >> "$REPORT"
  echo '```' >> "$REPORT"
  dig +nocmd +noall +answer +ttlid A "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### DNS — dig (AAAA record)" >> "$REPORT"
  echo '```' >> "$REPORT"
  dig +nocmd +noall +answer +ttlid AAAA "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### DNS — nslookup" >> "$REPORT"
  echo '```' >> "$REPORT"
  nslookup "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### TLS Certificate — openssl s_client" >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" | timeout 8 openssl s_client -connect "$domain":443 -servername "$domain" 2>&1 | grep -E "subject=|issuer=|Protocol|Cipher|Verify|CONNECTED|FAILED|error" || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### HTTP Response — curl" >> "$REPORT"
  echo '```' >> "$REPORT"
  curl -sv --max-time 10 --connect-timeout 6 -o /dev/null https://"$domain" 2>&1 | grep -E "^*|^>|^<|curl:" | head -40 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### Port Scan — nmap (ports 80, 443, 4000-4010)" >> "$REPORT"
  echo '```' >> "$REPORT"
  nmap -T4 --open -p 80,443,4000-4010 "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### Ping — local (4 packets)" >> "$REPORT"
  echo '```' >> "$REPORT"
  ping -c 4 -W 5 "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1

  echo "#### Traceroute — local" >> "$REPORT"
  echo '```' >> "$REPORT"
  traceroute -m 20 -w 3 "$domain" 2>&1 || true >> "$REPORT"
  echo '```' >> "$REPORT"
  echo "" >> "$REPORT"
  sleep 1
done

# PART 2 — Gulf region tests via Globalping
echo "## Gulf Region Tests (via Globalping)" >> "$REPORT"
echo "" >> "$REPORT"

for domain in "${DOMAINS[@]}"; do
  for region in "${GULF_REGIONS[@]}"; do
    echo "## $domain — $region" >> "$REPORT"
    echo "" >> "$REPORT"

    echo "### DNS Lookup (from $region)" >> "$REPORT"
    echo '```' >> "$REPORT"
    globalping dns "$domain" from "$region" --limit 1 --ci 2>&1 || true >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    sleep 3

    echo "### HTTP Probe (from $region)" >> "$REPORT"
    echo '```' >> "$REPORT"
    globalping http "$domain" from "$region" --limit 1 --method head --full --ci 2>&1 || true >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    sleep 3

    echo "### Ping (from $region)" >> "$REPORT"
    echo '```' >> "$REPORT"
    globalping ping "$domain" from "$region" --limit 1 --ci 2>&1 || true >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    sleep 3

    echo "### Traceroute (from $region)" >> "$REPORT"
    echo '```' >> "$REPORT"
    globalping traceroute "$domain" from "$region" --limit 1 --ci 2>&1 || true >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    sleep 3

    echo "### MTR — ping + traceroute combined (from $region)" >> "$REPORT"
    echo '```' >> "$REPORT"
    globalping mtr "$domain" from "$region" --limit 1 --ci 2>&1 || true >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    sleep 3
  done
done

# Footer
echo "## Interpretation Guide" >> "$REPORT"
echo "" >> "$REPORT"
echo "Report completed at: $(date)" >> "$REPORT"
echo "" >> "$REPORT"
echo "- DNS NXDOMAIN from Gulf = DNS-level block by ISP" >> "$REPORT"
echo "- Ping timeout from Gulf but DNS resolves = ICMP blocked, not DNS" >> "$REPORT"
echo "- HTTP 403 or TCP timeout from Gulf = firewall or DPI block on HTTPS" >> "$REPORT"
echo "- Traceroute stops mid-path in Gulf = gateway dropping packets" >> "$REPORT"
echo "- TLS failure = SNI-based blocking or certificate issue" >> "$REPORT"
echo "- Local passes, Gulf fails = geo-restriction confirmed" >> "$REPORT"