# Agora Gulf Connectivity Diagnostic Tool

## What This Is

This repository contains a GitHub Actions workflow that diagnoses connectivity issues for Agora-powered video classes in Gulf-region countries (Saudi Arabia, UAE, Qatar, Kuwait, Bahrain). It runs comprehensive network tests against Agora SDK domains both locally on GitHub's infrastructure and remotely from Gulf-region network probes using Globalping's free probe network, generating a detailed report to identify DNS blocks, firewalls, TLS SNI blocking, or ISP-level deep packet inspection.

## Why Globalping installs via apt, not npm

The @globalping/cli package does not exist on npm and was never published there, despite common assumptions. Globalping must be installed via the official apt repository using the packagecloud.io installation script, which provides the correct binary and dependencies.

## How to Trigger

1. Navigate to your GitHub repository
2. Click on the "Actions" tab
3. Select the "Agora Gulf Connectivity Check" workflow from the list
4. Click the "Run workflow" button
5. The workflow will start executing immediately

## Where to Download the Report

1. After the workflow run completes, go to the "Actions" tab in your repository
2. Click on the completed workflow run
3. Scroll down to the "Artifacts" section
4. Download the "agora-gulf-connectivity-report" artifact, which contains the report.md file

## What Each Test Means

| Test | Tool | What it detects |
|------|------|-----------------|
| Local DNS | dig, nslookup | DNS resolution from GitHub's infrastructure |
| TLS Check | openssl s_client | TLS certificate validation and SNI support |
| HTTP Status | curl | HTTP response codes and connection establishment |
| Port Scan | nmap | Open ports on target domains |
| Local Ping | ping | ICMP reachability from GitHub |
| Local Traceroute | traceroute | Network path from GitHub to target |
| Gulf DNS | globalping dns | DNS resolution from Gulf region probes |
| Gulf HTTP | globalping http | HTTP connectivity from Gulf region probes |
| Gulf Ping | globalping ping | ICMP reachability from Gulf region probes |
| Gulf Traceroute | globalping traceroute | Network path from Gulf region probes |
| Gulf MTR | globalping mtr | Combined ping and traceroute from Gulf region probes |

## How to Read Failures

- DNS NXDOMAIN from Gulf = DNS-level block by ISP
- Ping timeout from Gulf but DNS resolves = ICMP blocked, not DNS
- HTTP 403 or TCP timeout from Gulf = firewall or DPI block on HTTPS
- Traceroute stops mid-path in Gulf = gateway dropping packets
- TLS failure = SNI-based blocking or certificate issue
- Local passes, Gulf fails = geo-restriction confirmed