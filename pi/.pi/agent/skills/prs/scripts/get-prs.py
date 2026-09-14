#!/usr/bin/env python3
"""
Fetch recent PRs for the current user across repos or for a specific repo.
Identifies:
- To Merge: PRs that are approved, CI green, unblocked, and ready to merge right now.
- Action Needed: PRs requiring attention (failing CI with check name, changes requested with blocker, merge conflict).
- Stacked PRs: Indented underneath the bottom PR so you can see what's next, without status clutter on upper PRs.
- Waiting on Review: Open PRs waiting on reviewers or CI.
"""

import sys
import json
import re
import time
import subprocess
import argparse
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional, Tuple

GRAPHQL_QUERY = """
query($limit: Int!) {
  viewer {
    login
    pullRequests(first: $limit, states: [OPEN], orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        number
        title
        url
        isDraft
        updatedAt
        baseRefName
        headRefName
        mergeable
        mergeStateStatus
        reviewDecision
        repository {
          name
          nameWithOwner
          defaultBranchRef {
            name
          }
        }
        statusCheckRollup {
          state
          contexts(first: 15) {
            nodes {
              __typename
              ... on CheckRun {
                name
                conclusion
                status
              }
              ... on StatusContext {
                context
                state
              }
            }
          }
        }
        reviewThreads(first: 20) {
          nodes {
            isResolved
            isOutdated
            comments(first: 2) {
              nodes {
                author {
                  login
                }
                body
              }
            }
          }
        }
        latestReviews(first: 5) {
          nodes {
            author {
              login
            }
            state
            body
          }
        }
        reviewRequests(first: 5) {
          nodes {
            requestedReviewer {
              ... on User {
                login
              }
              ... on Team {
                name
                slug
              }
            }
          }
        }
      }
    }
  }
}
"""

REPO_ALIASES = {
    "frontend": "scribe-fe-v2",
    "fe": "scribe-fe-v2",
    "backend": "ml-scribe",
    "be": "ml-scribe",
    "widget": "scribe-js-plugin",
    "infra": "infra",
    "snowplow": "snowplow",
}

KNOWN_POD_MEMBERS = {
    "multiplayer-pod": {"daniel-heidi", "martin-luo-heidi", "igorrmotta", "the-vincent-y", "ClaudiaXu"},
    "integrations-pod": {"andyepifani", "wozniakty", "srijanc", "eric-heidi", "judygab", "WillisGo"},
    "architect-pod": {"wangdicoder", "johnnyheidi", "DemiJiang", "jack-heidi", "ameer-heidi"},
    "scribe-pod": {"jingmeng-heidi"},
    "eng-platform": {"michaelzheng-heidi"},
}

def rel_time(iso_str: str) -> str:
    """Format ISO timestamp into relative time like '15h ago', '2d ago'."""
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        diff = now - dt
        secs = int(diff.total_seconds())
        if secs < 60:
            return "just now"
        elif secs < 3600:
            return f"{max(1, secs // 60)}m ago"
        elif secs < 86400:
            return f"{secs // 3600}h ago"
        elif secs < 86400 * 30:
            return f"{secs // 86400}d ago"
        else:
            return f"{secs // (86400 * 30)}mo ago"
    except Exception:
        return ""

def get_age_days(iso_str: str) -> float:
    """Return age in days."""
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        return (now - dt).total_seconds() / 86400.0
    except Exception:
        return 0.0

def get_current_branch() -> Optional[str]:
    """Get the active git branch name if inside a git repo."""
    try:
        res = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            check=True
        )
        b = res.stdout.strip()
        return b if b and b != "HEAD" else None
    except Exception:
        return None

def fetch_prs(limit: int = 30) -> Tuple[str, List[Dict[str, Any]]]:
    """Fetch viewer's open PRs via GitHub CLI GraphQL with automatic retries."""
    cmd = [
        "gh", "api", "graphql",
        "-F", f"limit={limit}",
        "-f", f"query={GRAPHQL_QUERY}"
    ]
    last_err = ""
    for attempt in range(3):
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            viewer = data["data"]["viewer"]["login"]
            nodes = data["data"]["viewer"]["pullRequests"]["nodes"]
            return viewer, nodes
        last_err = res.stderr
        time.sleep(1)

    sys.stderr.write(f"Error calling GitHub API after 3 attempts: {last_err}\n")
    sys.exit(1)

def get_failing_checks(pr: Dict[str, Any]) -> List[str]:
    """Extract names of failing checks."""
    rollup = pr.get("statusCheckRollup") or {}
    if rollup.get("state") != "FAILURE":
        return []
    failing = []
    for ctx in rollup.get("contexts", {}).get("nodes", []):
        name = ctx.get("name") or ctx.get("context")
        conclusion = ctx.get("conclusion") or ctx.get("state")
        if conclusion in ("FAILURE", "TIMED_OUT", "ACTION_REQUIRED") and name and name != "CI Status":
            if " / " in name:
                name = name.split(" / ")[-1]
            if name not in failing:
                failing.append(name)
    return failing

def extract_critical_comments(pr: Dict[str, Any]) -> List[str]:
    """Extract unresolved critical comments or reviewer blocker notes."""
    crit = []
    for r in pr.get("latestReviews", {}).get("nodes", []):
        if r.get("state") == "CHANGES_REQUESTED":
            author = r.get("author", {}).get("login", "reviewer")
            body = r.get("body", "")
            m = re.search(r"###?\s*(?:Blocker|CRITICAL)[^\n]*", body, re.IGNORECASE)
            if m:
                header = m.group(0).strip("# ").strip()
                crit.append(f"{author} [{header}]")
            else:
                crit.append(f"{author} [changes requested]")

    threads = pr.get("reviewThreads", {}).get("nodes", [])
    for t in threads:
        if t.get("isResolved"):
            continue
        for c in t.get("comments", {}).get("nodes", []):
            author = c.get("author", {}).get("login", "")
            body = c.get("body", "")
            if author == "hubert-code-surgeon":
                clean = re.sub(r"<[^>]+>", "", body)
                m = re.search(r"!\[(CRITICAL|Suggestion|Nit)\]\([^)]+\)\s*\*?\*?\s*([^\n*]+)", clean)
                if m:
                    kind = m.group(1)
                    title = m.group(2).strip().rstrip("*")
                    if kind == "CRITICAL":
                        crit.append(f"Hubert [CRITICAL]: {title}")
            elif author and author not in ("cursor", pr.get("author", {}).get("login", "")):
                lines = [line.strip() for line in body.split("\n") if line.strip() and not line.strip().startswith("<!--")]
                if lines:
                    first_line = lines[0]
                    if len(first_line) > 75:
                        first_line = first_line[:72] + "..."
                    crit.append(f"{author}: {first_line}")
    return crit

def parse_reviews(pr: Dict[str, Any]) -> Tuple[str, List[str], List[str], List[str]]:
    """Return review decision label, approvers, changes requested authors, and unsatisfied requested reviewers."""
    decision = pr.get("reviewDecision") or "NONE"
    approvers = []
    changes_req = []
    for r in pr.get("latestReviews", {}).get("nodes", []):
        author = r.get("author", {}).get("login", "")
        state = r.get("state", "")
        if state == "APPROVED" and author and author not in approvers:
            approvers.append(author)
        elif state == "CHANGES_REQUESTED" and author and author not in changes_req:
            changes_req.append(author)

    team_members: Dict[str, set] = {}
    requested_raw = []
    for req in pr.get("reviewRequests", {}).get("nodes", []):
        reviewer = req.get("requestedReviewer") or {}
        name = reviewer.get("name") or reviewer.get("login") or reviewer.get("slug")
        if not name:
            continue
        clean_name = name.replace("oscerai/", "")

        # Deduplicate stream suffixes
        if any(stream in clean_name for stream in ("-workspace-stream", "-collab-stream", "-identity-stream")):
            continue

        if clean_name not in requested_raw:
            requested_raw.append(clean_name)

        members = set(KNOWN_POD_MEMBERS.get(clean_name, set()))
        for m in reviewer.get("members", {}).get("nodes", []):
            if m.get("login"):
                members.add(m["login"])
        team_members[clean_name] = members

    # Filter out pods already satisfied by an approver
    unsatisfied = []
    for team in requested_raw:
        members = team_members.get(team, set())
        if members and any(a in members for a in approvers):
            continue
        unsatisfied.append(team)

    return decision, approvers, changes_req, unsatisfied

def build_stacks(repo_prs: List[Dict[str, Any]]) -> Tuple[List[List[Dict[str, Any]]], List[Dict[str, Any]]]:
    """
    Group PRs into:
    - stacks: List of stacks [bottom_pr, middle_pr_1, ..., top_pr]
    - standalone: Single unstacked PRs
    """
    head_to_pr = {p["headRefName"]: p for p in repo_prs}
    children: Dict[str, List[Dict[str, Any]]] = {}
    for p in repo_prs:
        children.setdefault(p["baseRefName"], []).append(p)

    stacked_prs = set()
    bottom_candidates = []

    for p in repo_prs:
        base = p["baseRefName"]
        head = p["headRefName"]
        is_child = base in head_to_pr
        has_children = head in children

        if is_child or has_children:
            stacked_prs.add(p["number"])
            if not is_child:
                bottom_candidates.append(p)

    stacks = []
    visited = set()

    for bottom in bottom_candidates:
        stack = []
        curr = bottom
        while curr and curr["number"] not in visited:
            stack.append(curr)
            visited.add(curr["number"])
            next_prs = children.get(curr["headRefName"], [])
            if next_prs:
                curr = next_prs[0]
            else:
                curr = None
        if len(stack) > 1:
            stacks.append(stack)

    # Any stacked PR not covered in bottom_candidates
    unvisited_stacked = [p for p in repo_prs if p["number"] in stacked_prs and p["number"] not in visited]
    if unvisited_stacked:
        stacks.append(unvisited_stacked)

    standalone = [p for p in repo_prs if p["number"] not in stacked_prs]
    return stacks, standalone

def classify_pr(pr: Dict[str, Any]) -> Tuple[str, str]:
    """
    Classify a bottom-of-stack or standalone PR into category:
    "TO_MERGE", "ACTION", "WAITING", "DRAFT"
    Returns (category, reason_text).
    """
    is_draft = pr.get("isDraft", False)
    ci_state = (pr.get("statusCheckRollup") or {}).get("state", "NONE")
    failing_checks = get_failing_checks(pr)
    merge_state = pr.get("mergeStateStatus", "UNKNOWN")
    review_decision, approvers, changes_req, requested = parse_reviews(pr)
    critical_comments = extract_critical_comments(pr)

    # 1. Action Needed
    if changes_req:
        detail = critical_comments[0] if critical_comments else f"by {', '.join(changes_req)}"
        return "ACTION", f"🔴 Changes requested ({detail})"
    if merge_state == "DIRTY":
        return "ACTION", "🔴 Merge conflict / rebase needed"
    if ci_state == "FAILURE":
        fail_desc = f" ({failing_checks[0]})" if failing_checks else ""
        return "ACTION", f"🔴 CI failing{fail_desc}"
    if critical_comments:
        return "ACTION", f"🔴 Critical comment: {critical_comments[0]}"

    # 2. To Merge (strictly approved + CI green + clean)
    if (
        review_decision == "APPROVED"
        and ci_state == "SUCCESS"
        and merge_state not in ("DIRTY", "BLOCKED")
        and not is_draft
    ):
        return "TO_MERGE", "🟢 Ready to merge!"

    if is_draft:
        return "DRAFT", "📝 Draft (WIP)"

    # 3. Waiting on review / CI
    if review_decision == "REVIEW_REQUIRED":
        app_suffix = f" ({len(approvers)} approved)" if approvers else ""
        if len(requested) == 2:
            return "WAITING", f"Waiting on 2 codeowners: {requested[0]}, {requested[1]}{app_suffix}"
        elif len(requested) == 1:
            return "WAITING", f"Waiting on {requested[0]}{app_suffix}"
        elif len(requested) > 2:
            names_str = ", ".join(requested[:3])
            more = f" +{len(requested)-3}" if len(requested) > 3 else ""
            return "WAITING", f"Waiting on {len(requested)} codeowners: {names_str}{more}{app_suffix}"
        return "WAITING", f"Waiting on review{app_suffix}"

    if ci_state == "PENDING":
        return "WAITING", "CI running"

    return "WAITING", "In review"

def format_item(item: Dict[str, Any], current_branch: Optional[str] = None) -> str:
    """Format PR title and branch."""
    cur_badge = " ● `(current)`" if (current_branch and item['headRefName'] == current_branch) else ""
    return f"**[#{item['number']}]({item['url']})** `{item['headRefName']}`{cur_badge}: {item['title']}"

def render_entry_with_stack(
    root: Dict[str, Any],
    children: List[Dict[str, Any]],
    reason: str,
    current_branch: Optional[str] = None
) -> List[str]:
    """Render a root PR (bottom or standalone) with its stack indented underneath."""
    lines = []
    cur_badge = " ● `(current)`" if (current_branch and root['headRefName'] == current_branch) else ""
    t_rel = rel_time(root.get("updatedAt", ""))
    t_str = f" ({t_rel})" if t_rel else ""
    lines.append(f"- **[#{root['number']}]({root['url']})** `{root['headRefName']}`{cur_badge}{t_str}: {reason}")

    # Indent child PRs in the stack with flat 2-space bullet indent
    for child in children:
        child_badge = " ● `(current)`" if (current_branch and child['headRefName'] == current_branch) else ""
        lines.append(f"  - **[#{child['number']}]({child['url']})** `{child['headRefName']}`{child_badge}: {child['title']}")

    return lines

def render_output(
    viewer: str,
    prs_by_repo: Dict[str, List[Dict[str, Any]]],
    current_branch: Optional[str] = None,
    filter_repo: Optional[str] = None
) -> str:
    # Filter repos if requested
    target_repos = sorted(prs_by_repo.keys())
    if filter_repo:
        norm = REPO_ALIASES.get(filter_repo.lower(), filter_repo.lower())
        target_repos = [r for r in target_repos if norm in r.lower()]

    if not target_repos:
        return f"No open PRs found for **{viewer}**."

    # Buckets per repo: repo -> list of rendered line groups
    to_merge_by_repo: Dict[str, List[List[str]]] = {}
    action_by_repo: Dict[str, List[List[str]]] = {}
    waiting_by_repo: Dict[str, List[List[str]]] = {}
    older_action_by_repo: Dict[str, List[Dict[str, Any]]] = {}

    for repo_name in target_repos:
        repo_prs = prs_by_repo.get(repo_name, [])
        stacks, standalone = build_stacks(repo_prs)

        # 1. Process stacks (root is stack[0] / BOTTOM)
        for stack in stacks:
            bottom_pr = stack[0]
            children = stack[1:]
            cat, reason = classify_pr(bottom_pr)

            entry_lines = render_entry_with_stack(bottom_pr, children, reason, current_branch)
            if cat == "TO_MERGE":
                to_merge_by_repo.setdefault(repo_name, []).append(entry_lines)
            elif cat == "ACTION":
                action_by_repo.setdefault(repo_name, []).append(entry_lines)
            else:
                waiting_by_repo.setdefault(repo_name, []).append(entry_lines)

        # 2. Process standalone PRs
        for p in standalone:
            cat, reason = classify_pr(p)
            age = get_age_days(p.get("updatedAt", ""))
            
            # Collapse older inactive PRs (>14d) with conflicts/failing CI to avoid clutter
            if cat == "ACTION" and age > 14.0:
                older_action_by_repo.setdefault(repo_name, []).append(p)
                continue

            entry_lines = render_entry_with_stack(p, [], reason, current_branch)
            if cat == "TO_MERGE":
                to_merge_by_repo.setdefault(repo_name, []).append(entry_lines)
            elif cat == "ACTION":
                action_by_repo.setdefault(repo_name, []).append(entry_lines)
            else:
                waiting_by_repo.setdefault(repo_name, []).append(entry_lines)

    out = []

    # === SECTION 1: TO MERGE ===
    out.append("### 🟢 To Merge")
    if to_merge_by_repo:
        for repo_name, entries in to_merge_by_repo.items():
            if len(target_repos) > 1:
                out.append(f"\n**{repo_name}**")
            for entry in entries:
                out.extend(entry)
    else:
        out.append("*(None right now — waiting on CI or reviews)*")
    out.append("")

    # === SECTION 2: ACTION NEEDED ===
    if action_by_repo or older_action_by_repo:
        out.append("### 🔴 Action Needed")
        for repo_name in target_repos:
            entries = action_by_repo.get(repo_name, [])
            older = older_action_by_repo.get(repo_name, [])
            if not entries and not older:
                continue
            if len(target_repos) > 1:
                out.append(f"\n**{repo_name}**")
            for entry in entries:
                out.extend(entry)
            if older:
                older_links = [f"[#{p['number']}]({p['url']})" for p in older]
                out.append(f"  *+ {len(older)} older inactive PRs (>14d): {', '.join(older_links)}*")
        out.append("")

    # === SECTION 3: WAITING / IN REVIEW ===
    if waiting_by_repo:
        out.append("### ⏳ In Review / Waiting")
        for repo_name, entries in waiting_by_repo.items():
            if len(target_repos) > 1:
                out.append(f"\n**{repo_name}**")
            for entry in entries:
                out.extend(entry)
        out.append("")

    return "\n".join(out)

def main():
    parser = argparse.ArgumentParser(description="Get recent PRs and stacked PR status across all repos.")
    parser.add_argument("filter", nargs="?", default=None, help="Optional repo filter ('backend', 'frontend', 'infra')")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
    parser.add_argument("--limit", type=int, default=30, help="PR limit (default 30)")
    args = parser.parse_args()

    viewer, pr_nodes = fetch_prs(limit=args.limit)

    prs_by_repo: Dict[str, List[Dict[str, Any]]] = {}
    for p in pr_nodes:
        repo_name = p["repository"]["nameWithOwner"]
        prs_by_repo.setdefault(repo_name, []).append(p)

    current_branch = get_current_branch()

    filter_repo = args.filter if (args.filter and args.filter.lower() != "all") else None

    if args.json:
        print(json.dumps(pr_nodes, indent=2))
        return

    output = render_output(viewer, prs_by_repo, current_branch, filter_repo)
    print(output)

if __name__ == "__main__":
    main()
