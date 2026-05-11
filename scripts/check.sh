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

echo "Generating HTML report from $REPORT" >> "$REPORT" 2>/dev/null || true
HTML_REPORT="report.html"
cat > "$HTML_REPORT" <<HTML_HEAD
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Agora Gulf Connectivity Report</title>
  <style>
    body { font-family: Inter, ui-sans-serif, system-ui, sans-serif; background: #f8fafc; color: #111827; margin: 0; padding: 0; }
    .container { max-width: 1080px; margin: auto; padding: 24px; }
    h1, h2, h3, h4, h5 { color: #111827; }
    h1 { font-size: 2.1rem; margin-bottom: 0.5rem; }
    h2 { font-size: 1.55rem; border-bottom: 2px solid #e2e8f0; padding-bottom: 0.35rem; }
    h3 { font-size: 1.25rem; margin-top: 1.4rem; }
    p { margin: 0.75rem 0; }
    .meta { background: #e2e8f0; border-radius: 12px; padding: 16px; margin-bottom: 24px; }
    .code-block { background: #0f172a; color: #e2e8f0; padding: 16px; border-radius: 10px; overflow-x: auto; white-space: pre-wrap; font-family: ui-monospace, SFMono-Regular, Consolas, Liberation Mono, monospace; font-size: 0.92rem; line-height: 1.5; margin: 0.75rem 0; }
    ul { margin: 0.75rem 0 0.75rem 1.25rem; }
    li { margin: 0.35rem 0; }
    .footer { margin-top: 2rem; color: #475569; font-size: 0.95rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Agora Gulf Connectivity Report</h1>
    <div class="meta">
      <p>Generated on: $(date)</p>
    </div>
HTML_HEAD

echo "<div class=\"report-body\">" >> "$HTML_REPORT"
awk '
  BEGIN { in_code = 0; in_list = 0 }
  function esc(str) {
    gsub(/&/, "&amp;", str)
    gsub(/</, "&lt;", str)
    gsub(/>/, "&gt;", str)
    return str
  }
  /^[[:space:]]*```[[:space:]]*$/ {
    if (in_code) { print "</code></pre>"; in_code = 0 }
    else { print "<pre><code>"; in_code = 1 }
    next
  }
  if (in_code) {
    print esc($0)
    next
  }
  if ($0 ~ /^[[:space:]]*$/) {
    if (in_list) { print "</ul>"; in_list = 0 }
    next
  }
  if ($0 ~ /^#{1,6} /) {
    if (in_list) { print "</ul>"; in_list = 0 }
    level = length(substr($0, 1, index($0, " ") - 1))
    text = substr($0, index($0, " ") + 1)
    print "<h" level ">" esc(text) "</h" level ">"
    next
  }
  if ($0 ~ /^- /) {
    if (!in_list) { print "<ul>"; in_list = 1 }
    item = substr($0, 3)
    print "<li>" esc(item) "</li>"
    next
  }
  print "<p>" esc($0) "</p>"
  if (in_list) { print "</ul>"; in_list = 0 }
' "$REPORT" >> "$HTML_REPORT" || true

echo "</div>" >> "$HTML_REPORT"
cat >> "$HTML_REPORT" <<'HTML_FOOT'
  </div>
</body>
</html>
HTML_FOOT

# Ensure HTML generation never aborts the report flow
true