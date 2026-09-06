#!/usr/bin/env python3
"""
One-time setup script: creates everything CodeMate needs in Polar (polar.sh)
via their API, then patches the two Swift files that need the resulting IDs
and checkout URLs.

Creates, for organization POLAR_ORG_ID:
  - 2 License Keys benefits: "Pro Access", "Max Access"
  - 4 recurring products: Pro Monthly/Yearly, Max Monthly/Yearly
    (prices match what's already shown in PaywallView/SubscriptionTier.swift)
  - attaches the matching benefit to each product's pair
  - 1 checkout link per product

Then rewrites:
  - Sources/CodeMate/Services/PolarService.swift  (organizationId, benefitTierMap)
  - Sources/CodeMate/Models/SubscriptionTier.swift (the 4 purchaseURL placeholders)

Safe to re-run: it looks up existing products/benefits by name first instead
of creating duplicates.

Usage:
    export POLAR_TOKEN="polar_oat_..."     # your organization access token
    python3 Scripts/setup_polar.py

Do NOT commit POLAR_TOKEN anywhere, and don't paste it back into chat again --
treat it as already exposed since it was shared once in plaintext; consider
rotating it in the Polar dashboard (Settings -> API Keys) once this is done.
"""

import json
import os
import re
import sys
import urllib.request
import urllib.error
from pathlib import Path

ORG_ID = "36a24ca3-4af7-4c52-8fac-7243fb07019a"
API_BASE = "https://api.polar.sh/v1"

REPO_ROOT = Path(__file__).resolve().parent.parent
POLAR_SERVICE_SWIFT = REPO_ROOT / "Sources/CodeMate/Services/PolarService.swift"
SUBSCRIPTION_TIER_SWIFT = REPO_ROOT / "Sources/CodeMate/Models/SubscriptionTier.swift"

# name -> (recurring_interval, price_amount_cents) -- matches placeholderPrice
# values already in SubscriptionTier.swift so the UI and Polar stay in sync.
PRODUCTS = {
    "CodeMate Pro Monthly": ("month", 999, "pro", "pro-monthly"),
    "CodeMate Pro Yearly": ("year", 7999, "pro", "pro-yearly"),
    "CodeMate Max Monthly": ("month", 1999, "max", "max-monthly"),
    "CodeMate Max Yearly": ("year", 14999, "max", "max-yearly"),
}

BENEFITS = {
    "pro": "Pro Access",
    "max": "Max Access",
}


def die(msg):
    print(f"\nERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def api(method, path, body=None, params=None):
    url = f"{API_BASE}{path}"
    if params:
        qs = "&".join(f"{k}={urllib.request.quote(str(v))}" for k, v in params.items())
        url = f"{url}?{qs}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    # Polar sits behind Cloudflare, which blocks the default
    # "Python-urllib/x.y" user agent outright (HTTP 403, cf error 1010) --
    # a normal-looking UA gets through fine.
    req.add_header("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) CodeMateSetupScript/1.0")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body_text = e.read().decode()
        die(f"{method} {path} -> HTTP {e.code}\n{body_text}")


def find_product_by_name(name):
    result = api("GET", "/products/", params={"organization_id": ORG_ID, "query": name, "limit": 100})
    for p in result.get("items", []):
        if p["name"] == name:
            return p
    return None


def find_benefit_by_description(description):
    result = api("GET", "/benefits/", params={"organization_id": ORG_ID, "type": "license_keys", "limit": 100})
    for b in result.get("items", []):
        if b["description"] == description:
            return b
    return None


def create_benefit(description):
    print(f"  creating benefit '{description}'...")
    return api("POST", "/benefits/", body={
        # organization_id omitted: an org-scoped token (polar_oat_...) infers
        # it automatically and 422s if it's also set explicitly in the body.
        "type": "license_keys",
        "description": description,
        "properties": {},
    })


def create_product(name, interval, price_cents):
    print(f"  creating product '{name}' ({interval}, ${price_cents/100:.2f})...")
    return api("POST", "/products/", body={
        # organization_id omitted here too, same reason as create_benefit above.
        "name": name,
        "recurring_interval": interval,
        "prices": [{"amount_type": "fixed", "price_amount": price_cents, "price_currency": "usd"}],
    })


def attach_benefit(product_id, benefit_id):
    api("POST", f"/products/{product_id}/benefits", body={"benefits": [benefit_id]})


def find_checkout_link_by_label(label):
    result = api("GET", "/checkout-links/", params={"organization_id": ORG_ID, "limit": 100})
    for c in result.get("items", []):
        if c.get("label") == label:
            return c
    return None


def create_checkout_link(product_id, label):
    print(f"  creating checkout link '{label}'...")
    return api("POST", "/checkout-links/", body={
        "payment_processor": "stripe",
        "products": [product_id],
        "label": label,
    })


def patch_file(path, replacements):
    text = path.read_text()
    for old, new in replacements:
        if old not in text:
            print(f"  WARNING: expected text not found in {path.name}, skipping that replacement:\n    {old[:80]}...")
            continue
        text = text.replace(old, new)
    path.write_text(text)
    print(f"  patched {path.relative_to(REPO_ROOT)}")


def main():
    global TOKEN
    TOKEN = os.environ.get("POLAR_TOKEN")
    if not TOKEN:
        die("Set POLAR_TOKEN in your environment first:\n  export POLAR_TOKEN=\"polar_oat_...\"")

    print(f"Organization: {ORG_ID}\n")

    print("Benefits:")
    benefit_ids = {}
    for tier, description in BENEFITS.items():
        existing = find_benefit_by_description(description)
        if existing:
            print(f"  found existing benefit '{description}' ({existing['id']})")
            benefit_ids[tier] = existing["id"]
        else:
            created = create_benefit(description)
            benefit_ids[tier] = created["id"]

    print("\nProducts + checkout links:")
    checkout_urls = {}
    for name, (interval, price_cents, tier, slug) in PRODUCTS.items():
        product = find_product_by_name(name)
        if product:
            print(f"  found existing product '{name}' ({product['id']})")
        else:
            product = create_product(name, interval, price_cents)

        attach_benefit(product["id"], benefit_ids[tier])

        link = find_checkout_link_by_label(slug)
        if link:
            print(f"    found existing checkout link for '{slug}'")
        else:
            link = create_checkout_link(product["id"], slug)
        checkout_urls[slug] = link["url"]

    print("\nSummary:")
    print(f"  organization_id: {ORG_ID}")
    print(f"  pro benefit_id:  {benefit_ids['pro']}")
    print(f"  max benefit_id:  {benefit_ids['max']}")
    for slug, url in checkout_urls.items():
        print(f"  {slug}: {url}")

    print("\nPatching Swift source files:")
    patch_file(POLAR_SERVICE_SWIFT, [
        (
            'static let organizationId = "REPLACE_WITH_YOUR_POLAR_ORGANIZATION_ID"',
            f'static let organizationId = "{ORG_ID}"',
        ),
        (
            'static let benefitTierMap: [String: SubscriptionTier] = [:]\n'
            '    // Fill in once your benefits exist, e.g.:\n'
            '    // "b1b2c3d4-...": .pro,\n'
            '    // "e5f6a7b8-...": .max,',
            'static let benefitTierMap: [String: SubscriptionTier] = [\n'
            f'        "{benefit_ids["pro"]}": .pro,\n'
            f'        "{benefit_ids["max"]}": .max,\n'
            '    ]',
        ),
    ])
    patch_file(SUBSCRIPTION_TIER_SWIFT, [
        ('https://buy.codemate.app/pro-monthly', checkout_urls["pro-monthly"]),
        ('https://buy.codemate.app/pro-yearly', checkout_urls["pro-yearly"]),
        ('https://buy.codemate.app/max-monthly', checkout_urls["max-monthly"]),
        ('https://buy.codemate.app/max-yearly', checkout_urls["max-yearly"]),
    ])

    print("\nDone. Run `swift build` to confirm it still compiles, then test a")
    print("checkout link end to end (Polar test mode if you haven't gone live yet).")


if __name__ == "__main__":
    main()
