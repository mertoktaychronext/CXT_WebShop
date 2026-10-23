#!/usr/bin/env python3
"""
Veröffentlicht Markdown-Dateien aus dem Repo als Confluence-Seiten.

- Bestehende Seiten werden über page_id (oder Titel im Space) aktualisiert.
- Fehlende Seiten werden unter parent_id neu angelegt.
- Unveränderte Dateien werden übersprungen (Hash in der Versionsnachricht).

Aufruf:
    python tools/publish_confluence.py --config docs/confluence-pages.json [--dry-run]

Umgebungsvariablen:
    CONFLUENCE_USER   E-Mail des (technischen) Atlassian-Kontos
    CONFLUENCE_TOKEN  API-Token dieses Kontos
    CONFLUENCE_BASE_URL  optional, überschreibt base_url aus der Config
"""

import argparse
import hashlib
import html
import json
import os
import re
import sys
from pathlib import Path

import markdown
import requests

HASH_PREFIX = "repo-sha:"


# ---------------------------------------------------------------------------
# Markdown -> Confluence Storage Format
# ---------------------------------------------------------------------------

CODE_BLOCK_RE = re.compile(
    r'<pre><code(?: class="language-([\w+-]+)")?>(.*?)</code></pre>', re.DOTALL
)


# Sprachen, die das Confluence-Code-Makro kennt; AL wird als Delphi (Pascal-Syntax) dargestellt
CODE_LANGS = {
    "al": "delphi", "pascal": "delphi", "delphi": "delphi",
    "bash": "bash", "sh": "bash", "shell": "bash", "powershell": "powershell", "ps1": "powershell",
    "json": "json", "xml": "xml", "yaml": "yaml", "yml": "yaml", "sql": "sql",
    "python": "py", "py": "py", "csharp": "csharp", "cs": "csharp",
    "javascript": "js", "js": "js", "typescript": "typescript", "ts": "typescript",
    "java": "java", "html": "html", "css": "css",
}


def _code_macro(match: re.Match) -> str:
    lang = CODE_LANGS.get((match.group(1) or "").lower(), "none")
    code = html.unescape(match.group(2)).replace("]]>", "]]]]><![CDATA[>")
    return (
        '<ac:structured-macro ac:name="code">'
        f'<ac:parameter ac:name="language">{lang}</ac:parameter>'
        f"<ac:plain-text-body><![CDATA[{code}]]></ac:plain-text-body>"
        "</ac:structured-macro>"
    )


def _info_panel(text: str) -> str:
    return (
        '<ac:structured-macro ac:name="info">'
        f"<ac:rich-text-body><p>{html.escape(text)}</p></ac:rich-text-body>"
        "</ac:structured-macro>"
    )


def to_storage(md_text: str, source_hint: str) -> str:
    body = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "sane_lists"],
        output_format="xhtml",
    )
    body = CODE_BLOCK_RE.sub(_code_macro, body)
    notice = _info_panel(
        f"Diese Seite wird automatisch aus dem Repository erzeugt ({source_hint}). "
        "Änderungen bitte dort per Pull Request vornehmen – direkte Bearbeitungen "
        "hier werden beim nächsten Lauf überschrieben."
    )
    return notice + body


# ---------------------------------------------------------------------------
# Confluence REST API v2
# ---------------------------------------------------------------------------

class Confluence:
    def __init__(self, base_url: str, user: str, token: str):
        self.base = base_url.rstrip("/") + "/api/v2"
        self.s = requests.Session()
        self.s.auth = (user, token)
        self.s.headers.update({"Accept": "application/json",
                               "Content-Type": "application/json"})

    def _check(self, r: requests.Response) -> dict:
        if not r.ok:
            raise RuntimeError(f"{r.request.method} {r.url} -> {r.status_code}: {r.text[:500]}")
        return r.json() if r.content else {}

    def get_page(self, page_id: str) -> dict:
        return self._check(self.s.get(f"{self.base}/pages/{page_id}"))

    def find_by_title(self, space_id: str, title: str):
        r = self._check(self.s.get(f"{self.base}/pages",
                                   params={"space-id": space_id, "title": title}))
        results = r.get("results", [])
        return results[0] if results else None

    def update(self, page: dict, title: str, storage: str, message: str) -> dict:
        payload = {
            "id": page["id"],
            "status": "current",
            "title": title,
            "body": {"representation": "storage", "value": storage},
            "version": {"number": page["version"]["number"] + 1, "message": message},
        }
        return self._check(self.s.put(f"{self.base}/pages/{page['id']}", json=payload))

    def create(self, space_id: str, parent_id: str, title: str, storage: str) -> dict:
        payload = {
            "spaceId": space_id,
            "status": "current",
            "title": title,
            "parentId": parent_id,
            "body": {"representation": "storage", "value": storage},
        }
        return self._check(self.s.post(f"{self.base}/pages", json=payload))


# ---------------------------------------------------------------------------
# Ablauf
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    ap.add_argument("--dry-run", action="store_true",
                    help="Nur konvertieren und prüfen, nichts nach Confluence schreiben")
    ap.add_argument("--force", action="store_true",
                    help="Auch unveränderte Seiten neu schreiben")
    args = ap.parse_args()

    cfg_path = Path(args.config)
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    repo_root = Path(os.environ.get("BUILD_SOURCESDIRECTORY", "."))
    base_url = os.environ.get("CONFLUENCE_BASE_URL") or cfg["base_url"]

    conf = None
    if not args.dry_run:
        user, token = os.environ.get("CONFLUENCE_USER"), os.environ.get("CONFLUENCE_TOKEN")
        if not user or not token:
            print("##vso[task.logissue type=error]CONFLUENCE_USER/CONFLUENCE_TOKEN fehlen")
            return 1
        conf = Confluence(base_url, user, token)

    errors = 0
    for entry in cfg["pages"]:
        md_file = repo_root / entry["file"]
        title = entry["title"]
        if not md_file.exists():
            print(f"##vso[task.logissue type=error]Datei fehlt: {entry['file']}")
            errors += 1
            continue

        md_text = md_file.read_text(encoding="utf-8")
        digest = hashlib.sha256(md_text.encode("utf-8")).hexdigest()[:12]
        storage = to_storage(md_text, entry["file"])
        message = f"Automatisch aus Repo aktualisiert ({entry['file']}) {HASH_PREFIX}{digest}"

        if args.dry_run:
            print(f"[dry-run] {entry['file']} -> '{title}' ({len(storage)} Zeichen, {HASH_PREFIX}{digest})")
            continue

        try:
            page = None
            if entry.get("page_id"):
                page = conf.get_page(entry["page_id"])
            else:
                page = conf.find_by_title(cfg["space_id"], title)
                if page:
                    page = conf.get_page(page["id"])

            if page:
                last_msg = page.get("version", {}).get("message", "") or ""
                if not args.force and f"{HASH_PREFIX}{digest}" in last_msg:
                    print(f"= unverändert: {title}")
                    continue
                res = conf.update(page, title, storage, message)
                print(f"✓ aktualisiert: {title} (Version {res['version']['number']})")
            else:
                parent = entry.get("parent_id") or cfg["default_parent_id"]
                res = conf.create(cfg["space_id"], parent, title, storage)
                print(f"+ angelegt: {title} (ID {res['id']}) – page_id in der Config eintragen")
        except Exception as exc:  # noqa: BLE001
            print(f"##vso[task.logissue type=error]{title}: {exc}")
            errors += 1

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
