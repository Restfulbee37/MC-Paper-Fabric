#!/usr/bin/env python3

# This scraper is vibe coded :)

import json, time, sys
from typing import Dict, List, Optional
import requests
from collections import OrderedDict

MODRINTH_API = "https://api.modrinth.com/v2"
SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "mc-jars-json-builder/1.1 (+contact: you@example.com)",
    "Accept": "application/json",
})

MIN_INTERVAL = 0.5
_last_call = 0.0
def _throttle():
    global _last_call
    now = time.time()
    sleep_for = (_last_call + MIN_INTERVAL) - now
    if sleep_for > 0:
        print(f"[throttle] Sleeping {sleep_for:.2f}s...")
        time.sleep(sleep_for)
    _last_call = time.time()

def _get(url, **kwargs):
    tries, delay = 0, 1.0
    while True:
        _throttle()
        print(f"[http] GET {url} {kwargs.get('params','')}")
        resp = SESSION.get(url, timeout=30, **kwargs)
        if resp.status_code == 200:
            print(f"[http] 200 OK ({len(resp.content)} bytes)")
            return resp
        if resp.status_code in (429, 500, 502, 503, 504):
            retry_after = resp.headers.get("Retry-After")
            if retry_after:
                try:
                    delay = max(delay, float(retry_after))
                except ValueError:
                    pass
            tries += 1
            if tries > 6:
                print(f"[error] Too many retries, giving up")
                resp.raise_for_status()
            print(f"[warn] {resp.status_code}, retrying in {delay:.1f}s...")
            time.sleep(delay); delay = min(delay*2, 30); continue
        resp.raise_for_status()

def list_mc_versions() -> List[str]:
    print("[info] Fetching list of Minecraft versions...")
    r = _get(f"{MODRINTH_API}/tag/game_version")
    data = r.json()
    versions = [item["version"] for item in data if item.get("version_type") == "release"]
    def key(v: str): return tuple(int(x) for x in v.split("."))
    versions.sort(key=key, reverse=True)
    print(f"[info] Found {len(versions)} release versions (newest first).")
    return versions

PROJECTS = [
    ("fabricapi",    "P7dR8mSH", "fabric", "fabricapi"),
    ("fabricproxy",  "8dI2tmqs", "fabric", "fabricproxy"),
    ("bluemap-fab",  "bluemap",  "fabric", "bluemapfabric"),
    ("bluemap-ppr",  "bluemap",  "paper",  "bluemappaper"),
]

def latest_compatible_file_url(project_id: str, loader: str, mc_version: str) -> Optional[str]:
    params = {
        "loaders": json.dumps([loader]),
        "game_versions": json.dumps([mc_version]),
    }
    url = f"{MODRINTH_API}/project/{project_id}/version"
    print(f"[lookup] project={project_id} loader={loader} mc={mc_version}")
    resp = _get(url, params=params)
    versions = resp.json()
    if not versions:
        print(f"[miss] No versions for {project_id} ({loader}) on {mc_version}")
        return None

    ver = versions[0]
    print(f"[hit] Using version_number={ver.get('version_number')}")
    files = ver.get("files", [])

    for f in sorted(files, key=lambda f: not f.get("primary", False)):
        fn = f.get("filename", "")
        if fn.endswith(".jar"):
            file_url = f.get("url") or (f.get("downloads") or [None])[0]
            if file_url:
                print(f"[file] {fn} → {file_url}")
                return file_url
    print(f"[miss] No .jar file found in files list")
    return None

def build_matrix(mc_versions: List[str]) -> Dict[str, Dict[str, str]]:
    out: "OrderedDict[str, Dict[str, str]]" = OrderedDict()
    for v in mc_versions:
        print(f"\n=== Processing Minecraft {v} ===")
        row: Dict[str, str] = {}
        missing = []

        for (_nick, project_id, loader, out_key) in PROJECTS:
            try:
                url = latest_compatible_file_url(project_id, loader, v)
            except requests.HTTPError as e:
                print(f"[error] HTTP error for {project_id}: {e}")
                url = None
            if url:
                row[out_key] = url
            else:
                missing.append(out_key)

        if len(row) == len(PROJECTS):
            out[v] = row 
            print(f"[done] All 4 artifacts present for {v}; added to JSON")
        else:
            print(f"[skip] Missing {len(missing)} artifacts for {v}: {missing}; skipping")
    return out

def main():
    # Optional CLI bounds: python build_jars_json.py 1.20 1.21.99
    min_v = sys.argv[1] if len(sys.argv) >= 2 else None
    max_v = sys.argv[2] if len(sys.argv) >= 3 else None

    versions = list_mc_versions()
    if min_v: versions = [v for v in versions if v >= min_v]
    if max_v: versions = [v for v in versions if v <= max_v]

    matrix = build_matrix(versions)

    print("\n=== Writing jars.json ===")
    with open("jars.json", "w") as f:
        json.dump(matrix, f, indent=4, sort_keys=False)
    print("[done] jars.json written successfully")

if __name__ == "__main__":
    main()