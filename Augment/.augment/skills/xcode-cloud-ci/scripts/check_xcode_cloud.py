#!/Users/dbmrq/.augment/skills/xcode-cloud-ci/.venv/bin/python3
"""
Check Xcode Cloud CI status for recent builds.

Usage:
    check_xcode_cloud.py [--wait SECONDS] [--product PRODUCT_NAME] [--workflow WORKFLOW_NAME]

Options:
    --wait SECONDS      Wait up to SECONDS for the build to complete (polls every 30s)
    --product NAME      Filter by product/app name
    --workflow NAME     Filter by workflow name
    --list-products     List all Xcode Cloud products
    --list-workflows    List workflows for a product (requires --product)

Exit codes:
    0 - Success (build completed successfully)
    1 - Failure (build failed or error occurred)
    2 - Timeout (build still running after wait period)
    3 - No builds found

Credentials are read from ~/.config/app-store-connect/credentials.json
"""

import argparse
import json
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

try:
    import jwt
    import requests
except ImportError:
    print("Error: Required packages not installed.", file=sys.stderr)
    print("Run: pip3 install PyJWT requests", file=sys.stderr)
    sys.exit(1)

CREDENTIALS_PATH = Path.home() / ".config" / "app-store-connect" / "credentials.json"
API_BASE = "https://api.appstoreconnect.apple.com/v1"


def load_credentials():
    """Load API credentials from config file."""
    if not CREDENTIALS_PATH.exists():
        print(f"Error: Credentials file not found at {CREDENTIALS_PATH}", file=sys.stderr)
        print("\nCreate the file with:", file=sys.stderr)
        print(json.dumps({
            "issuer_id": "YOUR_ISSUER_ID",
            "key_id": "YOUR_KEY_ID", 
            "private_key_path": "~/.config/app-store-connect/AuthKey_XXXXXX.p8"
        }, indent=2), file=sys.stderr)
        sys.exit(1)
    
    with open(CREDENTIALS_PATH) as f:
        creds = json.load(f)
    
    # Load private key
    key_path = Path(creds["private_key_path"]).expanduser()
    if not key_path.exists():
        print(f"Error: Private key not found at {key_path}", file=sys.stderr)
        sys.exit(1)
    
    with open(key_path) as f:
        creds["private_key"] = f.read()
    
    return creds


def generate_token(creds):
    """Generate a JWT token for App Store Connect API."""
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=20)
    
    payload = {
        "iss": creds["issuer_id"],
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
        "aud": "appstoreconnect-v1"
    }
    
    return jwt.encode(
        payload,
        creds["private_key"],
        algorithm="ES256",
        headers={"kid": creds["key_id"]}
    )


def api_request(endpoint, token, params=None):
    """Make an authenticated API request."""
    headers = {"Authorization": f"Bearer {token}"}
    resp = requests.get(f"{API_BASE}{endpoint}", headers=headers, params=params)
    resp.raise_for_status()
    return resp.json()


def get_products(token):
    """Get all Xcode Cloud products."""
    data = api_request("/ciProducts", token, {"filter[productType]": "APP"})
    return data.get("data", [])


def get_workflows(token, product_id):
    """Get workflows for a product."""
    data = api_request(f"/ciProducts/{product_id}/workflows", token)
    return data.get("data", [])


def get_recent_builds_for_workflow(token, workflow_id, limit=5):
    """Get recent build runs for a specific workflow."""
    params = {"limit": limit}
    data = api_request(f"/ciWorkflows/{workflow_id}/buildRuns", token, params)
    return data.get("data", [])


def get_build_actions(token, build_id):
    """Get actions (jobs) for a build run."""
    data = api_request(f"/ciBuildRuns/{build_id}/actions", token)
    return data.get("data", [])


def format_build_status(build):
    """Format build status for display."""
    attrs = build.get("attributes", {})
    status = attrs.get("executionProgress", "UNKNOWN")
    completion = attrs.get("completionStatus", "")

    if status == "COMPLETE":
        if completion == "SUCCEEDED":
            return "✅ SUCCEEDED"
        elif completion == "FAILED":
            return "❌ FAILED"
        elif completion == "CANCELED":
            return "⚪ CANCELED"
        else:
            return f"⚠️ {completion}"
    else:
        return f"⏳ {status}"


def print_build_info(build, verbose=False):
    """Print build information."""
    attrs = build.get("attributes", {})
    print(f"Build: {build['id'][:8]}...")
    print(f"Status: {format_build_status(build)}")
    print(f"Started: {attrs.get('startedDate', 'N/A')}")
    if attrs.get("finishedDate"):
        print(f"Finished: {attrs['finishedDate']}")
    print(f"Source: {attrs.get('sourceCommit', {}).get('commitSha', 'N/A')[:7]}")


def check_build_status(token, product_name=None, workflow_name=None):
    """Check the status of the most recent build."""
    products = get_products(token)

    if not products:
        print("No Xcode Cloud products found.")
        return 3

    # Filter by product name if specified
    if product_name:
        products = [p for p in products if product_name.lower() in
                   p.get("attributes", {}).get("name", "").lower()]
        if not products:
            print(f"No product matching '{product_name}' found.")
            return 3

    product = products[0]
    product_attrs = product.get("attributes", {})
    print(f"Product: {product_attrs.get('name', 'Unknown')}")

    # Get workflows
    workflows = get_workflows(token, product["id"])

    if not workflows:
        print("No workflows found for this product.")
        return 3

    # Filter by workflow name if specified
    if workflow_name:
        matching = [w for w in workflows if workflow_name.lower() in
                   w.get("attributes", {}).get("name", "").lower()]
        if matching:
            workflows = matching

    # Get recent builds from first matching workflow
    all_builds = []
    for workflow in workflows:
        workflow_attrs = workflow.get("attributes", {})
        builds = get_recent_builds_for_workflow(token, workflow["id"])
        for b in builds:
            b["_workflow_name"] = workflow_attrs.get("name", "Unknown")
        all_builds.extend(builds)

    if not all_builds:
        print("No recent builds found.")
        return 3

    # Sort by creation date (newest first)
    all_builds.sort(key=lambda b: b.get("attributes", {}).get("createdDate", ""), reverse=True)

    build = all_builds[0]
    print(f"Workflow: {build.get('_workflow_name', 'Unknown')}")
    print()
    print_build_info(build)

    attrs = build.get("attributes", {})
    status = attrs.get("executionProgress", "")
    completion = attrs.get("completionStatus", "")

    if status == "COMPLETE":
        if completion == "SUCCEEDED":
            return 0
        else:
            return 1
    else:
        return 2


def list_products(token):
    """List all Xcode Cloud products."""
    products = get_products(token)
    if not products:
        print("No Xcode Cloud products found.")
        return

    print("Xcode Cloud Products:")
    for p in products:
        attrs = p.get("attributes", {})
        print(f"  - {attrs.get('name', 'Unknown')} (ID: {p['id'][:8]}...)")


def list_workflows(token, product_name):
    """List workflows for a product."""
    products = get_products(token)
    products = [p for p in products if product_name.lower() in
               p.get("attributes", {}).get("name", "").lower()]

    if not products:
        print(f"No product matching '{product_name}' found.")
        return

    product = products[0]
    workflows = get_workflows(token, product["id"])

    if not workflows:
        print("No workflows found.")
        return

    print(f"Workflows for {product.get('attributes', {}).get('name')}:")
    for w in workflows:
        attrs = w.get("attributes", {})
        print(f"  - {attrs.get('name', 'Unknown')}")


def main():
    parser = argparse.ArgumentParser(description="Check Xcode Cloud CI status")
    parser.add_argument("--wait", type=int, default=0,
                       help="Wait up to SECONDS for build to complete")
    parser.add_argument("--product", help="Filter by product/app name")
    parser.add_argument("--workflow", help="Filter by workflow name")
    parser.add_argument("--list-products", action="store_true",
                       help="List all Xcode Cloud products")
    parser.add_argument("--list-workflows", action="store_true",
                       help="List workflows (requires --product)")
    args = parser.parse_args()

    creds = load_credentials()
    token = generate_token(creds)

    if args.list_products:
        list_products(token)
        return 0

    if args.list_workflows:
        if not args.product:
            print("Error: --list-workflows requires --product", file=sys.stderr)
            return 1
        list_workflows(token, args.product)
        return 0

    # Check build status
    result = check_build_status(token, args.product, args.workflow)

    if result != 2 or args.wait == 0:
        return result

    # Poll until complete or timeout
    elapsed = 0
    poll_interval = 30

    while elapsed < args.wait:
        print(f"\nWaiting {poll_interval}s... ({elapsed}s / {args.wait}s elapsed)")
        time.sleep(poll_interval)
        elapsed += poll_interval

        # Regenerate token if needed (tokens last 20 min)
        if elapsed % 900 == 0:
            token = generate_token(creds)

        print()
        result = check_build_status(token, args.product, args.workflow)

        if result != 2:
            return result

    print(f"\n⏱️ Timeout: Build still running after {args.wait}s")
    return 2


if __name__ == "__main__":
    sys.exit(main())

