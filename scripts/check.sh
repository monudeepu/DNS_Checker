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
REGIONS=(
  "Bahrain"
  "United Arab Emirates"
  "Saudi Arabia"
  "Qatar"
  "Kuwait"
)

{
  echo "# Gulf Agora Connectivity Diagnostic Report"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo ""
  echo "This report was produced by running Globalping measurements (DNS, HTTPS, ping, traceroute) from Gulf-region probes toward each configured domain."
  echo ""
} >"$REPORT"

for domain in "${DOMAINS[@]}"; do
  for region in "${REGIONS[@]}"; do
    {
      echo "## \`${domain}\` — ${region}"
      echo ""
      echo "### DNS Lookup"
      echo ""
      echo '```'
      globalping dns "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 2

    {
      echo "### HTTPS (HTTP probe)"
      echo ""
      echo '```'
      globalping http "$domain" from "$region" --limit 1 --method head --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 2

    {
      echo "### Ping"
      echo ""
      echo '```'
      globalping ping "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 2

    {
      echo "### Traceroute"
      echo ""
      echo '```'
      globalping traceroute "$domain" from "$region" --limit 1 --ci 2>&1 || true
      echo '```'
      echo ""
    } >>"$REPORT"
    sleep 2
  done
done