## What This Is

This repository contains a small GitHub Actions workflow and shell script that run the free [Globalping](https://globalping.io/) CLI from four Gulf-area probe locations against six domains. Each domain and region pair is exercised with DNS resolution, an HTTPS-oriented HTTP probe, ICMP ping, and traceroute so you can spot DNS, TLS or HTTP reachability, latency, and path issues affecting users around the Gulf without installing probes yourself.

## How to Trigger

1. Open the repository on GitHub.
2. Select the **Actions** tab.
3. Choose **Gulf Agora connectivity check** in the workflow list on the left.
4. Click **Run workflow**, leave inputs empty (there are none), and confirm with **Run workflow**.

## Downloading the Report

1. After the run finishes, open the same workflow run from the **Actions** tab.
2. Scroll to the **Artifacts** section at the bottom of the run summary.
3. Download **agora-gulf-connectivity-report** (a zip file).
4. Unzip the archive; it contains `report.md` at the root of the zip.

## What Each Test Means

| Test | Command | What It Detects |
| --- | --- | --- |
| DNS Lookup | `globalping dns <domain> from <region> --limit 1 --ci` | Whether resolvers used by a probe in that region can resolve the hostname and what answers they return, including failures or unexpected records. |
| HTTPS Curl | `globalping http <domain> from <region> --limit 1 --method head --ci` | Whether an HTTPS-capable HTTP request from that region completes (TLS, routing, and basic HTTP availability), similar in spirit to `curl -I` against the host. |
| Ping | `globalping ping <domain> from <region> --limit 1 --ci` | ICMP reachability and round-trip latency from the chosen region toward the target, highlighting packet loss or very high latency. |
| Traceroute | `globalping traceroute <domain> from <region> --limit 1 --ci` | The forward path and hops from the probe to the destination, useful for seeing where routing stalls or takes an unexpected detour. |

## Domains Tested

- `api.agora.io`
- `docs.agora.io`
- `console.agora.io`
- `agora.io`
- `google.com`
- `cloudflare.com`

## Regions Tested

- Bahrain
- United Arab Emirates
- Saudi Arabia
- Qatar
