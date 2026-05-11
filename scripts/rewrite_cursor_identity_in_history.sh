#!/usr/bin/env bash
# Rewrite Git history so Cursor Agent does not remain a GitHub "contributor".
#
# GitHub counts contributors from commit *author* and *committer* identities,
# not only "Co-authored-by:" trailers. See:
# https://github.com/orgs/community/discussions/186158
#
# Requires: git, git-filter-repo (brew install git-filter-repo | pip install git-filter-repo)
#
# Usage (mirror workflow — safest for a full remote rewrite):
#   export TARGET_NAME="Your Legal Name"
#   export TARGET_EMAIL="your@email.com"
#   ./scripts/rewrite_cursor_identity_in_history.sh git@github.com:USER/REPO.git
#
# Optional overrides:
#   CURSOR_EMAILS="cursoragent@users.noreply.github.com,cursoragent@cursor.com"
#   CURSOR_NAMES="cursoragent,Cursor Agent,Cursoragent"
#   CURSOR_SUBSTRINGS="cursoragent,cursor agent,@cursor.com"
#
# After success: contributor graph may lag; disconnect Cursor in GitHub
# Settings → Applications / Installed GitHub Apps as well.
#
set -euo pipefail

REPO_URL="${1:-}"
TARGET_NAME="${TARGET_NAME:-$(git config --global --get user.name 2>/dev/null || true)}"
TARGET_EMAIL="${TARGET_EMAIL:-$(git config --global --get user.email 2>/dev/null || true)}"
CURSOR_EMAILS="${CURSOR_EMAILS:-cursoragent@users.noreply.github.com,cursoragent@cursor.com}"
CURSOR_NAMES="${CURSOR_NAMES:-cursoragent,Cursor Agent,Cursoragent}"
CURSOR_SUBSTRINGS="${CURSOR_SUBSTRINGS:-cursoragent,cursor agent,@cursor.com}"

WORKDIR="${WORKDIR:-}"

if [[ -z "$REPO_URL" ]]; then
  echo "ERROR: pass the repository URL (use a mirror clone + force push workflow)."
  echo "Example: TARGET_NAME='Jane Doe' TARGET_EMAIL='jane@example.com' \\"
  echo "  $0 git@github.com:USER/REPO.git"
  exit 1
fi

if [[ -z "$TARGET_NAME" || -z "$TARGET_EMAIL" ]]; then
  echo "ERROR: set TARGET_NAME and TARGET_EMAIL, or configure git user.name / user.email."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found."
  exit 1
fi

if ! git filter-repo -h >/dev/null 2>&1; then
  echo "ERROR: git-filter-repo not installed."
  echo "  brew install git-filter-repo"
  echo "  python3 -m pip install --user git-filter-repo"
  exit 1
fi

if [[ -z "$WORKDIR" ]]; then
  WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/repo-clean-XXXXXX")"
  REMOVE_WORKDIR=1
else
  REMOVE_WORKDIR=0
fi

cleanup() {
  if [[ "${REMOVE_WORKDIR:-0}" -eq 1 && -n "${WORKDIR:-}" && -d "$WORKDIR" ]]; then
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

echo "Cloning mirror into: $WORKDIR"
git clone --mirror "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"

export FILTER_TARGET_NAME="$TARGET_NAME"
export FILTER_TARGET_EMAIL="$TARGET_EMAIL"
export FILTER_CURSOR_EMAILS="$CURSOR_EMAILS"
export FILTER_CURSOR_NAMES="$CURSOR_NAMES"
export FILTER_CURSOR_SUBSTRINGS="$CURSOR_SUBSTRINGS"

CALLBACK_FILE="$WORKDIR/__cursor_filter_callback.py"

cat >"$CALLBACK_FILE" <<'PY'
import os
import re

target_name = os.environ["FILTER_TARGET_NAME"].encode("utf-8")
target_email = os.environ["FILTER_TARGET_EMAIL"].encode("utf-8")

cursor_emails = {
    e.strip().lower().encode("utf-8")
    for e in os.environ["FILTER_CURSOR_EMAILS"].split(",")
    if e.strip()
}
cursor_names = {
    n.strip().lower().encode("utf-8")
    for n in os.environ["FILTER_CURSOR_NAMES"].split(",")
    if n.strip()
}
cursor_substrings = [
    s.strip().lower().encode("utf-8")
    for s in os.environ["FILTER_CURSOR_SUBSTRINGS"].split(",")
    if s.strip()
]


def looks_like_cursor_identity(name: bytes, email: bytes) -> bool:
    nl = name.lower().strip()
    el = email.lower().strip()
    if el in cursor_emails or nl in cursor_names:
        return True
    return any(sub in nl or sub in el for sub in cursor_substrings)


def strip_cursor_coauthored_trailers(message: bytes) -> bytes:
    text = message.decode("utf-8", errors="surrogateescape")
    # Lines like: Co-authored-by: Cursor <cursoragent@cursor.com>
    text = re.sub(
        r"(?m)^Co-authored-by:\s*.*cursoragent.*\n?",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"(?m)^Co-authored-by:\s*Cursor\s*<[^>]+>\s*\n?",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r"\n{3,}\Z", "\n\n", text)
    return text.encode("utf-8", errors="surrogateescape")


# `commit` is provided by git-filter-repo in the callback namespace; load with globals().
if looks_like_cursor_identity(commit.author_name, commit.author_email):
    commit.author_name = target_name
    commit.author_email = target_email

if looks_like_cursor_identity(commit.committer_name, commit.committer_email):
    commit.committer_name = target_name
    commit.committer_email = target_email

commit.message = strip_cursor_coauthored_trailers(commit.message)
PY

echo "Rewriting commits (author, committer, and Co-authored-by trailers)..."
git filter-repo --force --commit-callback "exec(open(r'${CALLBACK_FILE}').read(), globals())"

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "$REPO_URL"
fi

echo "Force-pushing mirror to origin (rewrites all branches and tags)..."
git push --force --mirror origin

echo "Done. Refresh GitHub Contributors after a few minutes; revoke Cursor app access if still linked."
