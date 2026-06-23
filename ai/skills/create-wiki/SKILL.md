---
name: create-wiki
description: Deep-investigate a codebase and generate a single-page project wiki at .docs/index.html. Use this skill whenever the user asks to "create a wiki", "generate docs", "document this project", "explain this codebase", "make a project wiki", or wants a comprehensive HTML overview of a repository. Also trigger when the user says /create-wiki. Even if the user just says "wiki" in the context of documentation, use this skill.
---

# Create Wiki

Generate a comprehensive single-page wiki for any codebase, saved to `.docs/index.html`. The wiki explains the project's architecture, implementation, and key systems in **explanatory narrative prose** — not terse reference tables or bullet-point dumps.

## Process

1. **Investigate** — Launch parallel agents to deeply explore the codebase
2. **Plan** — Decide which sections are relevant based on findings
3. **Generate** — Build the HTML wiki using the bundled template
4. **Refine** — Review for completeness and readability

---

## Step 1: Investigate the Codebase

Speed matters here — launch **6–8 parallel exploration agents** to cover the codebase from different angles.
Before launching, detect the project stack by reading the package manager manifest (package.json, pyproject.toml, go.mod, Cargo.toml, etc.) so you can tailor agent prompts.

The goal is not a surface-level summary.
Each agent must dig into actual source files, trace real call chains, and report **specific file paths, class names, function names, and interface names** — not generic descriptions.
Vague findings like "this service handles business logic" are not acceptable.

### Agent Prompts (adapt to the project)

**Agent 1 — Overview & Entry Points:**
Read the package manifest, README, CLAUDE.md / AGENTS.md, and all main entry points.
Identify the framework, key dependencies, and project purpose.
Find the top-level architectural boundary: where does execution start, what are the primary modules, and how are they wired together?
Report exact file paths for entry points and wiring code.

**Agent 2 — Layered Architecture:**
Map the system into logical layers (e.g. UI / Service / Model / Extension, or Handler / Domain / Repository / Infrastructure).
For each layer, list the key files and the interfaces or base classes that define the layer's contract.
Identify which layer owns what responsibility and how layers communicate (direct call, event bus, DI container, etc.).
Cite exact file paths for each layer boundary.

**Agent 3 — Core Domain Logic:**
Explore the main source directories (services/, models/, lib/, core/, domain/, src/).
Understand the primary domain abstractions: what are the key types, what invariants do they enforce, and how does data transform as it flows through them?
Trace at least one complete end-to-end operation from entry point to storage or output, noting every function and file touched.

**Agent 4 — Data Flow & Request Lifecycle:**
Pick the most important operation in the system (HTTP request, event, job, command, etc.) and trace it completely.
Start from where it enters the process, follow it through every layer — routing, validation, business logic, persistence, response — and note each file, function, and key decision point.
Identify where state is mutated, where errors are handled, and where async boundaries exist.

**Agent 5 — API / Routes / CLI / Extension Points:**
Explore API routes, controllers, handlers, middleware, CLI command definitions, or plugin/extension registrations.
Map the full interface surface: endpoints, parameters, auth patterns, response shapes.
Note which handler calls which service, and where the boundary between input parsing and business logic sits.
Cite exact file paths for route/command registration.

**Agent 6 — Data & Infrastructure:**
Investigate database schema, migrations, ORM config, CI/CD pipelines, Dockerfile, configuration loading, environment variables, background jobs, queues, and cron tasks.
Report the names of every env var, every queue/topic, and every scheduled job, with the file where each is defined or consumed.

**Agent 7 — Performance, Memory & Techniques:**
Hunt specifically for performance-sensitive code: caching layers, lazy initialization, pooling, memoization, batching, streaming, virtualization, and memory-conscious patterns.
Look for any algorithmic tricks, non-obvious data structures, lock-free patterns, or techniques borrowed from well-known literature.
Note benchmark files, perf tests, profiling hooks, or any comments referencing specific papers, blog posts, or external resources.
For each finding, record the file path, what the technique is, and why it matters for this system.

**Agent 8 — Component Relationships, Testing & Observability:**
Find the central interfaces, abstract classes, and DI bindings that hold the system together.
Build a component map: for each major component, list what it depends on and what depends on it.
Explore test structure and frameworks, coverage patterns, monitoring setup, structured logging, and metrics/tracing instrumentation.
Note which parts of the system are well-tested vs. lightly tested.

Skip agents that don't apply.
A CLI tool doesn't need an API routes agent.
A backend service doesn't need a UI agent.
A library doesn't need a CI/CD agent.
Use your judgment.

---

## Step 2: Plan Sections

Based on investigation results, decide which sections to include in the wiki.

**Always include:**
- Overview (what the project is, what it does, tech badges)
- Architecture (layered breakdown with file citations per layer)
- Data Flow (end-to-end trace of the most important operation)
- Project Structure (annotated file tree)
- Development Commands (how to run, build, test)

**Include if the project has them:**
- Tech Stack (when there are enough interesting dependencies to warrant a section)
- Component Relationships (matrix or diagram of how key components depend on each other)
- Key Flows / Lifecycle (additional processes beyond the primary data flow)
- API Routes (REST/GraphQL/gRPC endpoints)
- Background Workers (queues, cron, async processing)
- Database (schema, migrations, access patterns)
- Integrations (third-party services and how they're used)
- Services (core business logic layer, when complex enough)
- Configuration (env vars, config loading strategy)
- Performance, Memory & Techniques (caching, pooling, algorithmic tricks, non-obvious optimizations — with links to relevant papers, blog posts, or docs)
- Monitoring & Metrics (observability stack)
- CI/CD & Deployment (build pipeline, Docker, deploy process)
- UI & Pages (frontend pages and components)
- Testing (test strategy, frameworks, how to run)

Order sections so earlier ones provide context for later ones.
Architecture before implementation details.
Core flows before supporting infrastructure.
Performance section near the end, after the reader understands what is being optimized.

---

## Step 3: Generate the Wiki

### Theming: DESIGN.md or Neutral

Before generating, check if a `DESIGN.md` file exists in the project root. This changes how you style the wiki:

**If DESIGN.md exists:** Read it and map its design tokens (colors, fonts, spacing, shadows, radii) onto the CSS variables in the template. Replace the neutral defaults with the project's brand colors, typography, and elevation system. For example, if DESIGN.md specifies a primary accent of `#7610C6` and a font of "Neue Haas Grotesk Text", update `--accent`, `--accent-hover`, `--accent-surface`, and the `font-family` in the template accordingly. Apply both light and dark mode tokens if the design system defines them.

**If no DESIGN.md exists:** Use the template as-is — it ships with a neutral gray/slate palette and system fonts that look clean and professional without any brand identity.

### Using the Template

Read the template from `references/template.html` in this skill's directory. It provides the complete HTML/CSS/JS shell — sidebar, theme toggle, responsive layout, and all component styles.

### Using the Template

1. Read the template file
2. Replace `{{PROJECT_NAME}}` with the project name
3. Build the sidebar `<nav>` with `<a href="#section-id">` links for each section
4. Fill the `<main>` element with your content sections
5. Write the complete file to `.docs/index.html` (create `.docs/` if needed)

### Content Writing Guidelines

The most important thing: **write like you're explaining the project to a smart new team member**, not generating API reference docs.
Every section should help the reader build a mental model of *why* things work the way they do.

**For each section:**
1. Open with a paragraph explaining the purpose and context — why does this part of the system exist?
2. Add detailed subsections with narrative explanations
3. Use tables and code blocks as *supporting material*, not as the primary content
4. Use callout boxes for important warnings, gotchas, or non-obvious behavior
5. Connect to other sections ("this is consumed by the SQS handler described above")
6. **Cite actual source files** — every significant claim should name the file (and ideally the function or class) where you found it

**For the Architecture section specifically:**
Present the system as explicit layers.
For each layer, write a short paragraph describing its responsibility, then list the key files with one-line annotations.
Show how layers communicate — a flow diagram works well here.

**For the Data Flow section:**
Trace one complete request or operation end-to-end.
Name every function and file it passes through.
Use a flow diagram to show the happy path, then prose to explain branches, error handling, and async steps.

**For the Performance, Memory & Techniques section:**
Each technique gets its own subsection with: what it is, where it's used (file + function), why it matters for this system, and a link to a reference (MDN, paper, blog post, or docs) if one exists.
Use technique cards (see HTML components below) to make each entry visually distinct.
Be specific: "uses a 64-entry LRU cache in `src/cache/query-cache.ts` to avoid redundant DB calls on hot paths" beats "caches query results".

**What to avoid:**
- Sections that are just a table with no surrounding explanation
- Bullet-point-only sections with no narrative context
- Repeating information that's already in another section
- Generic descriptions that could apply to any project ("this service handles business logic")

**What to aim for:**
- Concrete references to actual file paths, function names, and class names
- Explanations of non-obvious design decisions and tradeoffs
- Descriptions of how data flows between components
- "Why" before "what" — motivation before mechanics

### HTML Components Available

The template CSS supports these components:

**Flow diagrams** — for multi-step processes:
```html
<div class="flow">
  <div class="flow-steps">
    <span class="flow-step blue">Step 1</span>
    <span class="flow-arrow">&rarr;</span>
    <span class="flow-step green">Step 2</span>
    <span class="flow-arrow">&rarr;</span>
    <span class="flow-step purple">Step 3</span>
  </div>
</div>
```
Colors: `blue`, `green`, `orange`, `purple`, `cyan`.

**Callout boxes** — for warnings and notes:
```html
<div class="callout info"><strong>Note:</strong> message here</div>
<div class="callout warn"><strong>Warning:</strong> message here</div>
```

**File tree** — for project structure (whitespace-preserving):
```html
<div class="file-tree">
<span class="dir">project/</span>
├── <span class="dir">src/</span>
│   ├── <span class="file">index.ts</span>   <span class="comment"># Entry point</span>
│   └── <span class="dir">lib/</span>        <span class="comment"># Utilities</span>
└── <span class="file">package.json</span>
</div>
```

**Tables** — for structured reference data:
```html
<table>
  <thead><tr><th>Column</th><th>Description</th></tr></thead>
  <tbody><tr><td>value</td><td>explanation</td></tr></tbody>
</table>
```

**Component relationship matrix** — for showing how modules depend on each other:
```html
<table class="matrix">
  <thead>
    <tr><th>Component</th><th>Depends On</th><th>Used By</th><th>Notes</th></tr>
  </thead>
  <tbody>
    <tr>
      <td><code>ChatService</code></td>
      <td><code>SessionStore</code>, <code>ModelRouter</code></td>
      <td><code>ChatWidget</code>, <code>InlineChat</code></td>
      <td>Owns session lifecycle</td>
    </tr>
  </tbody>
</table>
```

**Architecture layer block** — for the layered architecture section:
```html
<div class="arch-layer">
  <div class="arch-layer-label blue">UI Layer</div>
  <div class="arch-layer-files">
    <code>src/chat/browser/chatWidget.ts</code> — main chat panel<br>
    <code>src/chat/browser/inlineChat.ts</code> — in-editor chat
  </div>
</div>
```
Layer label colors: `blue` (UI), `green` (Service), `orange` (Model/Domain), `purple` (Infrastructure/Extension).

**Technique card** — for performance / memory / tricks sections:
```html
<div class="technique-card">
  <div class="technique-header">
    <span class="technique-name">LRU Query Cache</span>
    <a class="technique-link" href="https://en.wikipedia.org/wiki/Cache_replacement_policies#LRU" target="_blank">Reference &rarr;</a>
  </div>
  <p>Short explanation of what the technique does and why it matters here.</p>
  <div class="technique-source"><code>src/cache/query-cache.ts</code> &mdash; <code>QueryCache.get()</code></div>
</div>
```

**Source reference inline** — cite a file next to a claim:
```html
<span class="source-ref"><a href="#" title="src/services/auth.ts:42">src/services/auth.ts</a></span>
```

**Tags** — for HTTP methods or status labels:
```html
<span class="tag tag-green">GET</span>
<span class="tag tag-blue">POST</span>
<span class="tag tag-red">DELETE</span>
<span class="tag tag-orange">PATCH</span>
<span class="tag tag-purple">SOCKET</span>
```

**Tech badges** — for the hero section:
```html
<span class="tech-badge">Next.js</span>
<span class="tech-badge">PostgreSQL</span>
```

**Code blocks** — for config, schema, or code examples:
```html
<pre><code>const config = loadConfig();</code></pre>
```

---

## Step 4: Refine

After generating, check for:
- Sidebar links match section `id` attributes
- File tree renders correctly (the template has `white-space: pre` on `.file-tree`)
- No sections are still in terse/listy style — rewrite any that are
- Cross-references between sections are accurate
- The hero section is not styled as a card (it should be flat with a bottom border)
- Footer has the project name and generation date
- Architecture section has a proper layer breakdown, not just a paragraph
- Data Flow section traces a real operation with actual file/function names
- Performance section uses technique cards and every entry has a source file reference
- Any external links in technique cards open in a new tab (`target="_blank"`)

---

## Large Codebases

For large projects where generating everything at once would be unwieldy, break the generation into chunks:
1. Generate the HTML shell with sidebar, hero, and the first few sections
2. Add remaining sections in batches of 2–3, using Edit to append before the closing `</main>` tag
3. Each chunk should be self-contained enough to write in one edit

This avoids context pressure from trying to hold the entire wiki in a single generation pass.
