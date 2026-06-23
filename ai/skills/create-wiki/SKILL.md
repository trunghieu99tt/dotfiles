---
name: create-wiki
description: Deep-investigate a codebase and generate a multi-page HTML wiki in .docs/. Each major topic gets its own dedicated page with deep research, Mermaid diagrams, and real code citations. Use this skill whenever the user asks to "create a wiki", "generate docs", "document this project", "explain this codebase", "make a project wiki", or wants a comprehensive HTML overview of a repository. Also trigger when the user says /create-wiki.
---

# Create Wiki

Generate a **multi-page HTML wiki** for any codebase, saved to `.docs/`.
Each major topic gets its own dedicated page with deep research, Mermaid diagrams, real code snippets, and precise file citations — not terse summaries.

## Output Structure

```
.docs/
  index.html          - Overview, tech stack, site map with links to all pages
  architecture.html   - Layered architecture, component map, key abstractions
  data-flow.html      - End-to-end request/operation lifecycle traces
  api.html            - Full API/CLI surface with types and handler flow
  database.html       - Schema, ER diagram, migrations, access patterns
  services.html       - Core domain logic and business rules deep dive
  performance.html    - Caching, memory, algorithmic techniques with links
  testing.html        - Test strategy, frameworks, coverage map
  deployment.html     - CI/CD pipeline, env vars, Docker, infra topology
  [additional pages as warranted by the project]
```

Only generate pages that are genuinely relevant to the project.
A CLI library doesn't need `api.html` or `deployment.html`.
A pure frontend app doesn't need `database.html`.
Use judgment — a focused, deep wiki beats a sprawling one with thin pages.

## Process

1. **Scan** - Quick investigation to understand scope and decide the page list
2. **Deep Research** - One dedicated agent per page, running in parallel
3. **Generate** - Build each page using the template with Mermaid and cross-links
4. **Refine** - Verify all links, diagrams, cross-references, and quality

---

## Phase 1: Scan the Codebase

Do this yourself before launching any agents — it takes 3-5 tool calls:

- Read the package manifest (package.json, pyproject.toml, go.mod, Cargo.toml, etc.)
- Read the README and any CLAUDE.md / AGENTS.md
- List the top-level source directories
- Identify the framework, language, and project type

From this, decide:
1. Which pages to generate (the full site map)
2. What the primary tech stack is (tailor all agent prompts to it)
3. What the 2-3 most important operations in the system are (for data-flow agents)

---

## Phase 2: Deep Research (Parallel Agents)

Launch **one dedicated explore agent per page** in parallel.
Each agent owns its page completely — it reads actual source files, traces real call chains, and returns specific findings with file paths, function names, and code snippets.

Vague findings are not acceptable.
"This service handles business logic" is not a finding.
"The `OrderService.placeOrder()` method in `src/services/order.ts:142` validates stock, inserts a DB record via `OrderRepository.create()`, then dispatches an `order.placed` event to the SQS queue defined in `src/queue/topics.ts:18`" is a finding.

### Agent: Overview & Architecture

Investigate:
- Entry points and bootstrapping/wiring code (exact file paths)
- The logical layers of the system (e.g. UI / Service / Model / Infrastructure, or Handler / Domain / Repository)
- For each layer: key files, defining interfaces or base classes, how it communicates with adjacent layers
- The 5-10 most important types, classes, and interfaces — what invariants do they enforce?
- Component dependency map: for each major component, what does it depend on and what depends on it?
- Non-obvious design decisions: why is the system structured this way?

### Agent: Data Flow & Lifecycles

Pick the 2-3 most important operations and trace each completely:
- Start from where it enters the process (HTTP handler, CLI args, queue consumer, event listener)
- Follow through every layer: routing, validation, business logic, persistence, response
- Note every file and function touched, every state mutation, every async boundary, every error branch
- Identify where the "interesting" logic lives vs. where it's just plumbing
- Find any retry logic, circuit breakers, or distributed coordination

### Agent: API / CLI / Extension Points

Investigate the full public interface surface:
- Every route, endpoint, command, or plugin hook with exact registration file and line
- Handler signatures, middleware chain order, auth patterns
- Request/response shapes — look at the actual TypeScript types, Go structs, Pydantic models, etc.
- Which handler calls which service
- Error handling and status code conventions at the boundary
- Rate limiting, pagination, versioning if present

### Agent: Database & Data Models

Investigate:
- Schema definitions — ORM models, migration files, raw SQL schemas
- Every entity/table/collection: fields, types, constraints, indexes
- Relationships between entities (FK, references, embedding)
- Key queries and access patterns (find the hot paths in services/repositories)
- Migration strategy and any notable schema evolution decisions
- N+1 query risks or known performance considerations

### Agent: Core Services & Domain Logic

Investigate the business logic layer:
- What are the core service/module files?
- What business rules do they enforce? (Be specific — name the rules and the code that enforces them)
- How do services interact with each other?
- What are the non-obvious design decisions and their rationale?
- Are there interesting patterns: event sourcing, CQRS, saga, strategy, etc.?
- Where are the domain boundaries drawn?

### Agent: Performance, Memory & Techniques

Hunt specifically for:
- Caching layers: where, what's cached, TTL, eviction strategy, cache key construction
- Lazy initialization, object pooling, connection pool config
- Memoization, batching, debouncing, throttling implementations
- Streaming vs. buffering decisions
- Non-obvious data structures (tries, bloom filters, ring buffers, etc.)
- Lock-free patterns, concurrency primitives, worker pools
- Any code comments referencing papers, blog posts, or benchmarks
- Benchmark files, perf test suites, or profiling scripts

For every finding: file path, function name, what the technique is, why it matters here, and an external reference link if one exists (Wikipedia, MDN, paper, blog post).

### Agent: Testing & Observability

Investigate:
- Test directory structure and what types of tests exist (unit / integration / e2e / contract)
- Testing frameworks, key test utilities, and fixture/factory patterns
- Which parts of the system have strong coverage vs. gaps
- How tests are organized: co-located, separate directory, naming conventions
- Logging setup: library, structured fields, log levels used in practice
- Metrics: what's instrumented, what's emitted, what's tracked
- Tracing: distributed trace setup if any
- Alerting or SLO definitions if present

### Agent: Deployment & Infrastructure

Investigate:
- Dockerfile and docker-compose (what services, what ports, what volumes)
- CI/CD pipeline: what stages exist, what each does, what gates a deploy
- Complete env var catalog: name, required/optional, default, description, where consumed
- Configuration loading: which file, what precedence order, how validated
- Background jobs and cron tasks: schedule, what they do, failure handling
- Health check endpoints, readiness probes, graceful shutdown logic

---

## Phase 3: Generate Each Page

### Template

Read `references/template.html` from this skill's directory.
Use it as the shell for every page — it contains the CSS, the sidebar, theme toggle, and Mermaid initialization.

For each page:
1. Replace `{{PROJECT_NAME}}` with the project name
2. Replace `{{PAGE_TITLE}}` with the page's title (e.g. "Architecture")
3. Build the sidebar `<nav>` with links to **all generated pages** — not just sections of the current page.
   Mark the current page active: `<a href="architecture.html" class="active">Architecture</a>`
4. Fill `<main>` with the page content
5. Write to `.docs/<page-name>.html`

### Mermaid Diagrams

Every page must have **at least one Mermaid diagram**.
The template already includes the Mermaid CDN and initialization — just write `<div class="mermaid">` blocks.

Choose the right diagram type:

**Architecture / component dependencies — flowchart:**
```html
<div class="mermaid">
flowchart TD
  A[ChatWidget] --> B[IChatService]
  B --> C[ChatModel]
  B --> D[ModelRouter]
  D --> E[OpenAI API]
  D --> F[Anthropic API]
</div>
```

**Request lifecycle — sequence diagram:**
```html
<div class="mermaid">
sequenceDiagram
  participant C as Client
  participant R as Router
  participant S as OrderService
  participant DB as Database
  C->>R: POST /orders
  R->>S: placeOrder(dto)
  S->>DB: INSERT order
  DB-->>S: order row
  S-->>R: OrderResult
  R-->>C: 201 Created
</div>
```

**Database schema — ER diagram:**
```html
<div class="mermaid">
erDiagram
  USER ||--o{ ORDER : places
  ORDER ||--|{ LINE_ITEM : contains
  PRODUCT ||--o{ LINE_ITEM : "included in"
  ORDER {
    uuid id PK
    uuid user_id FK
    string status
    timestamp created_at
  }
</div>
```

**Class / interface relationships — class diagram:**
```html
<div class="mermaid">
classDiagram
  class IChatService {
    +sendMessage(req) Response
    +getSession(id) Session
  }
  class ChatService {
    -sessionStore SessionStore
    -modelRouter ModelRouter
    +sendMessage(req) Response
  }
  IChatService <|.. ChatService
  ChatService --> SessionStore
  ChatService --> ModelRouter
</div>
```

**State machine — state diagram:**
```html
<div class="mermaid">
stateDiagram-v2
  [*] --> Pending
  Pending --> Processing: job picked up
  Processing --> Complete: success
  Processing --> Failed: error
  Failed --> Pending: retry (max 3)
  Failed --> Dead: retries exhausted
</div>
```

**CI/CD pipeline or multi-step process — graph:**
```html
<div class="mermaid">
graph LR
  Lint --> Test
  Test --> Build
  Build --> Push["Push Image"]
  Push --> Deploy["Deploy Staging"]
  Deploy --> Smoke["Smoke Tests"]
  Smoke --> Prod["Deploy Prod"]
</div>
```

Use diagrams to show structure and flow, then prose to explain the *why*.
Never place a diagram without at least a paragraph before it setting context.

### Cross-linking Between Pages

Every page should reference related pages.
Use the `page-link` component for inline cross-links:
```html
<a href="architecture.html" class="page-link">Architecture &rarr;</a>
```

End every page with a "Related Pages" block:
```html
<div class="related-pages">
  <h3>Related Pages</h3>
  <div class="related-grid">
    <a href="data-flow.html" class="related-card">
      <strong>Data Flow</strong>
      <span>How requests travel through these layers end-to-end</span>
    </a>
    <a href="services.html" class="related-card">
      <strong>Services</strong>
      <span>The business logic that each layer calls into</span>
    </a>
  </div>
</div>
```

### Theming

Check if `DESIGN.md` exists in the project root.
If it does, read it and map its design tokens onto the CSS variables in the template.
If not, use the template as-is — it ships with a clean neutral palette.

### Content Standards

Write like you're explaining to a smart new team member who needs to understand *why*, not just *what*.

**Required for every page:**
- Open each major section with a paragraph explaining context and motivation before any code or diagrams
- Cite actual file paths and function/class names for every significant claim
- Use Mermaid diagrams to visualize structure, flow, and relationships
- Use callout boxes for gotchas, non-obvious behavior, and important warnings
- Connect to other pages where relevant

**Strictly avoid:**
- Bullet-point-only sections with no narrative
- Generic statements that could describe any codebase
- Diagrams without surrounding prose
- Sections that restate what's already covered on another page

### Page Content Guide

**`index.html` - Overview:**
- Hero: project name, one-paragraph description, tech badges
- What problem this solves and for whom
- A Mermaid flowchart showing the major components at a glance
- Site map: card grid linking to all pages, each with a one-sentence description
- Quick start: the 3-5 commands to get running

**`architecture.html` - Architecture:**
- Logical layers with an `arch-layer` block per layer (blue=UI, green=Service, orange=Domain, purple=Infrastructure)
- A Mermaid component diagram showing layer communication
- Class diagram for the 5-10 key abstractions
- Component dependency matrix table (component / depends on / used by / notes)
- Design decisions section: why is it structured this way?

**`data-flow.html` - Data Flow:**
- One Mermaid sequence diagram per traced operation
- Step-by-step narrative for each operation, citing every file and function
- Callout boxes for error paths, retry logic, and async boundaries
- State mutation map: what data changes at each step

**`api.html` - API / CLI:**
- Full endpoint/command table: method, path, auth, handler file, description
- Mermaid sequence diagram for each key endpoint's handler flow
- Request/response type definitions as code blocks from actual source
- Auth and middleware chain explanation with a Mermaid diagram

**`database.html` - Database:**
- Mermaid ER diagram for the full schema
- Per-entity section: fields, constraints, relationships, notable access patterns
- Key queries as actual SQL or ORM code lifted from source
- Migration strategy and schema evolution decisions
- Index rationale table

**`services.html` - Services:**
- Per-service section: purpose, public interface, business rules, dependencies
- Mermaid flowcharts for complex business logic (especially branching flows)
- Design patterns called out with their rationale

**`performance.html` - Performance:**
- Technique cards for each optimization with external reference links
- Mermaid diagrams showing cache topology or batching pipelines
- Benchmark results or profiling findings if present in source
- Known bottlenecks or areas flagged for improvement

**`testing.html` - Testing:**
- Mermaid diagram of the test pyramid (how many of each type)
- Per-layer coverage: what's tested, what's not
- Key test utilities and helpers with code examples
- How to run tests (exact copy-paste commands)

**`deployment.html` - Deployment:**
- Mermaid graph of the CI/CD pipeline stages
- Deployment topology diagram (services, ports, dependencies)
- Complete env var table: name / required / default / description / consumed in
- Health check and graceful shutdown behavior

---

## Phase 4: Refine

After all pages are generated, verify:
- Every sidebar link resolves to a file that was actually generated
- Current-page link has `class="active"` on each page
- Every Mermaid `<div class="mermaid">` block has valid syntax
- No page has bullet-only sections — every list has surrounding prose
- Cross-page links use relative paths (`architecture.html`, not `/architecture.html`)
- Footer on every page shows project name and generation date
- Technique cards on performance page all have a source file reference
- ER diagram covers all entities found during research

---

## Large Codebases

For very large pages, generate in chunks to avoid context pressure:
1. Write the HTML shell, sidebar, and hero for the page first
2. Add sections in batches of 2-3, using Edit to append before `</main>`
3. Each batch should be self-contained prose + diagram units

After all pages exist, do one final pass to add cross-links between them.
