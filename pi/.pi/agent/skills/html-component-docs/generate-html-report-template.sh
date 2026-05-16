#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <output-html-path> [title]" >&2
  exit 1
fi

output_path="$1"
title="${2:-HTML Report}"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <style>
    :root {
      --bg: #f8fafc;
      --card: #ffffff;
      --text: #172033;
      --muted: #667085;
      --border: #dbe3ef;
      --accent: #5956d6;
      --accent-2: #7c3aed;
      --code: #111827;
      --ok: #059669;
      --warn: #d97706;
      --bad: #dc2626;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font: 14px/1.55 Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    .layout {
      display: grid;
      grid-template-columns: 310px minmax(0, 1fr);
      min-height: 100vh;
    }

    aside {
      position: sticky;
      top: 0;
      height: 100vh;
      overflow-y: auto;
      padding: 28px 22px;
      border-right: 1px solid var(--border);
      background: #ffffff;
    }

    main {
      width: min(100%, 1080px);
      min-width: 0;
      margin: 0 auto;
      padding: 48px min(6vw, 72px) 96px;
    }

    .brand {
      padding: 18px;
      border-radius: 22px;
      background: linear-gradient(135deg, var(--accent), var(--accent-2));
      color: #ffffff;
      margin-bottom: 22px;
    }

    .brand h1 { font-size: 20px; line-height: 1.15; margin: 0 0 8px; }
    .brand p { margin: 0; opacity: 0.86; }

    .nav details {
      border: 1px solid var(--border);
      border-radius: 14px;
      background: #ffffff;
      margin: 12px 0;
      padding: 10px;
    }

    .nav summary { cursor: pointer; font-weight: 700; }

    .nav a {
      display: block;
      color: var(--muted);
      text-decoration: none;
      padding: 7px 6px;
      border-radius: 8px;
    }

    .nav a:hover { background: #f1f5f9; color: var(--accent); }

    .hero {
      border-radius: 28px;
      padding: 34px;
      background: linear-gradient(135deg, #ffffff, #f3f0ff);
      border: 1px solid var(--border);
      box-shadow: 0 20px 50px rgba(15, 23, 42, 0.06);
      margin-bottom: 22px;
    }

    .hero h2 { font-size: 36px; line-height: 1.08; margin: 0 0 12px; }
    .hero p { font-size: 16px; color: var(--muted); max-width: 760px; }

    .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }

    .stat {
      background: #ffffff;
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 18px;
    }

    .stat b { display: block; font-size: 26px; color: var(--accent); }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 22px;
      padding: 24px;
      margin: 18px 0;
    }

    .card h2 { margin: 0 0 14px; font-size: 24px; }
    .card h3 { margin: 22px 0 8px; font-size: 17px; }

    .callout {
      border-left: 4px solid var(--accent);
      background: #f5f3ff;
      border-radius: 14px;
      padding: 14px 16px;
      margin: 14px 0;
    }

    .callout.ok { border-left-color: var(--ok); background: #ecfdf5; }
    .callout.warn { border-left-color: var(--warn); background: #fffbeb; }
    .callout.bad { border-left-color: var(--bad); background: #fef2f2; }

    .table-wrap { overflow: auto; border: 1px solid var(--border); border-radius: 16px; }
    table { width: 100%; border-collapse: collapse; min-width: 820px; }
    th, td { padding: 12px 14px; border-bottom: 1px solid var(--border); vertical-align: top; text-align: left; }
    th { background: #f8fafc; font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: #475467; }
    tr:last-child td { border-bottom: 0; }

    .pill {
      display: inline-block;
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 4px 9px;
      background: #ffffff;
      color: #475467;
      margin: 2px;
      font-size: 12px;
    }

    .pill.ok { border-color: #a7f3d0; color: #047857; background: #ecfdf5; }
    .pill.warn { border-color: #fde68a; color: #92400e; background: #fffbeb; }
    .pill.bad { border-color: #fecaca; color: #991b1b; background: #fef2f2; }

    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      background: #eef2ff;
      color: #3730a3;
      border-radius: 6px;
      padding: 2px 5px;
    }

    pre {
      background: var(--code);
      color: #e5e7eb;
      border-radius: 16px;
      padding: 16px;
      overflow: auto;
    }

    .diagram {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 20px;
      background: linear-gradient(180deg, #ffffff, #f8fafc);
      padding: 18px;
      margin: 18px 0;
    }

    .diagram svg {
      display: block;
      min-width: 760px;
      width: 100%;
      height: auto;
    }

    .src { font-size: 12px; color: var(--muted); }
    ul { padding-left: 20px; }

    @media (max-width: 900px) {
      .layout { display: block; }
      aside { position: relative; height: auto; }
      .grid { grid-template-columns: 1fr; }
      main { padding: 28px 18px 64px; }
      .hero h2 { font-size: 28px; }
    }
  </style>
</head>
<body>
  <div class="layout">
    <aside>
      <div class="brand">
        <h1>${title}</h1>
        <p>Report / documentation</p>
      </div>
      <nav class="nav">
        <details open>
          <summary>Overview</summary>
          <a href="#summary">Summary</a>
          <a href="#quickstart">Quickstart</a>
          <a href="#goals">Goals</a>
        </details>
        <details open>
          <summary>Details</summary>
          <a href="#api">API</a>
          <a href="#contract">Contract</a>
          <a href="#examples">Examples</a>
        </details>
        <details>
          <summary>Internals</summary>
          <a href="#diagram">Diagram</a>
          <a href="#internal-workings">Internal workings</a>
          <a href="#notes">Notes</a>
        </details>
      </nav>
    </aside>

    <main>
      <section id="summary" class="hero">
        <h2>Replace with report summary.</h2>
        <p>Replace with one or two sentences explaining what this report covers and why it exists.</p>
        <div class="grid">
          <div class="stat"><b>0</b>Key metric</div>
          <div class="stat"><b>0</b>Key metric</div>
          <div class="stat"><b>0</b>Key metric</div>
        </div>
      </section>

      <section id="quickstart" class="card">
        <h2>Quickstart</h2>
        <p>Replace with minimal usage or fast read.</p>
      </section>

      <section id="goals" class="card">
        <h2>Goals and non-goals</h2>
        <ul>
          <li><strong>Goal:</strong> Replace me.</li>
          <li><strong>Non-goal:</strong> Replace me.</li>
        </ul>
      </section>

      <section id="api" class="card">
        <h2>API / endpoints / props</h2>
        <div class="table-wrap">
          <table>
            <thead>
              <tr><th>Name</th><th>Source</th><th>Purpose</th><th>Notes</th></tr>
            </thead>
            <tbody>
              <tr><td><code>ReplaceMe</code></td><td>File/path</td><td>Purpose</td><td><span class="pill ok">status</span></td></tr>
            </tbody>
          </table>
        </div>
      </section>

      <section id="contract" class="card">
        <h2>Content / data contract</h2>
        <div class="callout"><strong>Important:</strong> Replace with key contract note.</div>
        <pre>// Replace with concise example</pre>
      </section>

      <section id="examples" class="card">
        <h2>Examples</h2>
        <pre>// Replace with code example</pre>
      </section>

      <section id="diagram" class="card">
        <h2>Diagram</h2>
        <div class="diagram">
          <svg viewBox="0 0 760 220" role="img" aria-label="Replace diagram">
            <rect x="30" y="40" width="200" height="120" rx="18" fill="#f5f3ff" stroke="#c4b5fd" />
            <text x="55" y="105" font-size="16" font-weight="700" fill="#312e81">Replace</text>
            <rect x="300" y="40" width="200" height="120" rx="18" fill="#ffffff" stroke="#dbe3ef" />
            <text x="325" y="105" font-size="16" font-weight="700" fill="#172033">Replace</text>
            <rect x="570" y="40" width="160" height="120" rx="18" fill="#ffffff" stroke="#dbe3ef" />
            <text x="595" y="105" font-size="16" font-weight="700" fill="#172033">Replace</text>
          </svg>
        </div>
      </section>

      <section id="internal-workings" class="card">
        <h2>Internal workings</h2>
        <h3>Replace subsection</h3>
        <p>Replace with implementation detail.</p>
      </section>

      <section id="notes" class="card">
        <h2>Operational notes</h2>
        <div class="callout warn"><strong>Watch:</strong> Replace with limitation or follow-up.</div>
      </section>
    </main>
  </div>
</body>
</html>
EOF

echo "Wrote HTML report template: $output_path"
