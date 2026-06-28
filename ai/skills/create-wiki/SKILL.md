---
name: create-wiki
description: Deep-investigate a codebase and generate a multi-page HTML wiki in .docs/. Each major topic gets its own dedicated page with deep research, Mermaid diagrams, and real code citations. Use this skill whenever the user asks to "create a wiki", "generate docs", "document this project", "explain this codebase", "make a project wiki", or wants a comprehensive HTML overview of a repository. Also trigger when the user says /create-wiki.
---

# Create Wiki

Generate a **multi-page HTML wiki** for any codebase, saved to `.docs/`.
This is a deep technical specification, not a summary.
Each major topic gets its own dedicated page with deep research, Mermaid diagrams, real code snippets, and precise file citations.

## The Decision Lens (read this first)

The single most important rule: **for every significant design choice, explain the reasoning, not just the result.**
A wiki that says "uses Redis for caching" is useless.
A wiki that says "uses Redis for caching because the read-heavy session lookups need sub-millisecond latency across 4 app servers; an in-process LRU was rejected because sessions must survive deploys and be shared between instances; Memcached was considered but Redis was chosen for its built-in TTL and pub/sub used elsewhere" is what we want.

Apply this lens to **every** non-trivial element on every page:

1. **What** it is - the concrete mechanism, with file/function/line citations.
2. **Why** it exists - the problem it solves and the forces that shaped it.
3. **Alternatives** - what other approaches were possible, and why they were not chosen (infer from code, comments, git history, and your own engineering knowledge; clearly mark inference vs. fact).
4. **Fit** - why this specific approach fits the project's constraints, scale, and goals.
5. **Tradeoffs** - what this choice costs (complexity, coupling, performance, operational burden).

Render this reasoning using the `decision-box` component (defined in the template).
If you cannot find or reasonably infer the _why_ behind something important, say so explicitly rather than padding with generic filler.

## The Audience Lens (read this second)

**Write for an intern, fresher, or junior engineer on their first week — not for the senior who already wrote the code.**
The reader is smart but has no context: they may not know what a slab, a 3-index slice, an outbox, or a bloom filter is. Your job is to teach, not to impress.

This rule overrides any temptation to sound clever. A dense sentence packed with jargon is a failure, even if every word is technically correct.

Concretely, on every page:

1. **Define every piece of jargon the first time it appears.** Never use a term like "slab", "3-index slice", "backpressure", "arena", "zero-copy", or "CDC" without immediately explaining what it means in plain language. If a term has a one-line definition, give it inline. If it needs more, give it its own short paragraph before you use it in context.
2. **Spell out abbreviations and symbols.** Don't write `dst[lo:hi:hi]` and move on — say what `dst` is (the destination slice), what `lo` and `hi` are (the low and high bounds), and what the third index does and why it matters. Walk through the expression like you're at a whiteboard.
3. **Explain the _mechanism_, not just the label.** "Cache-friendly" is not an explanation. Explain _why_: e.g. "the CPU loads memory in 64-byte chunks called cache lines; keeping these structs next to each other in memory means one load brings in several of them, so the next few accesses are already in fast cache instead of going to slow main memory."
4. **Build up from the problem.** Start with the concrete problem in everyday terms ("allocating one object at a time is slow because every allocation asks the OS/runtime for memory"), then introduce the solution, then name the technique. Don't lead with the fancy name.
5. **Use concrete numbers and analogies** where they make the idea click ("a slab is like buying a 64 KB sheet of stamps once and tearing off individual stamps, instead of going to the post office for each stamp").
6. **Prefer short sentences.** One idea per sentence. If a sentence has three commas and four nouns the reader has never seen, break it apart.

**Bad (what to never produce):**

> For fixed-size structs that need a real `*T` pointer, a generic helper hands out 3-index sub-slices (`dst[lo:hi:hi]`) from 64 KB slabs, amortizing thousands of allocations and keeping same-type structs contiguous (cache-friendly).

**Good (what to produce instead):**

> Some objects (like per-group counters) need a stable pointer that stays valid for the whole program run. Allocating each one separately would mean thousands of tiny memory requests, which is slow and scatters the objects randomly across memory.
>
> Instead, the code allocates memory in big 64 KB blocks called **slabs** (think of a slab as one large tray). When it needs a new object, it carves a small piece off the current slab and hands that piece out, instead of asking the runtime for fresh memory each time. This is called a **slab allocator**.
>
> The piece it hands out is a **3-index slice**: `dst[lo:hi:hi]`. Here `dst` is the slab (the destination block), `lo` and `hi` mark where the object's bytes start and end, and the _third_ index (also `hi`) caps the slice's capacity so it can't accidentally grow into the next object's memory. Capping the capacity is what makes it safe to hand out many objects from one slab.
>
> Because objects of the same type sit right next to each other in the slab, they're **cache-friendly**: CPUs fetch memory in 64-byte chunks called cache lines, so reading one counter often pulls its neighbors into fast cache too — making the next reads nearly free.
>
> When a slab fills up, the code simply forgets its reference to it and allocates a new slab. The objects already handed out don't disappear: each one is kept alive by the slice still pointing into the old slab, so the garbage collector won't reclaim that memory until those slices are gone.

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

> [!IMPORTANT]
>
> ### MANDATORY: set the model on EVERY subagent call
>
> Subagents do **not** inherit your session's model. Named agents (like `Explore`) default to a small, fast model (e.g. gpt-mini). If you do not pass `model` explicitly on **each** `runSubagent` call, research silently runs on that cheap model and produces the vague findings this skill forbids.
>
> **Therefore, for every research agent you launch, you MUST set the `model` parameter explicitly. No exceptions.**
>
> - **Preferred model:** `model: "Claude Opus 4.8 (copilot)"` — with maximum reasoning effort / extended thinking and the 1M-token context window.
> - In the agent prompt, also request "use maximum reasoning effort / extended thinking" so the model runs at full depth.
> - **Do not rely on prose instructions inside the prompt to pick the model** — the `model` parameter is the only thing that actually controls it. The prompt text cannot change the model.
> - **Verify the exact string.** If `"Claude Opus 4.8 (copilot)"` is not an available model name, `runSubagent` silently falls back to the cheap default. Use the strongest reasoning model actually available to you (latest Opus tier, else top GPT/Gemini Pro tier). Never let it fall back to a small/fast model.
> - If you genuinely cannot pass a strong model (the parameter is rejected or no strong model exists), **stop and tell the user** before running research on a weak model — do not silently proceed.
>
> A correct launch looks like: `runSubagent(agentName: "Explore", model: "Claude Opus 4.8 (copilot)", prompt: "...use maximum reasoning effort...")`.

**Every agent must apply the Decision Lens.**
For each significant element it finds, the agent reports not just what the code does, but _why it was built that way, what alternatives existed, why they were rejected, and what tradeoffs the choice carries._
Instruct each agent: "For every notable design choice, infer and explain the reasoning. Look at code comments, commit messages (`git log`/`git blame` on the relevant files), naming, and surrounding context for clues. Where the intent is not documented, apply your engineering knowledge to explain the likely rationale and the realistic alternatives, and clearly label it as inference."

Vague findings are not acceptable.
"This service handles business logic" is not a finding.
"The `OrderService.placeOrder()` method in `src/services/order.ts:142` validates stock, inserts a DB record via `OrderRepository.create()`, then dispatches an `order.placed` event to the SQS queue defined in `src/queue/topics.ts:18`. It uses an outbox-pattern insert in the same transaction (lines 150-158) rather than publishing directly to SQS, almost certainly to avoid the dual-write problem where the DB commits but the queue publish fails" is a finding.

Tell each agent to return, per element: **what / why / alternatives considered / why this fits / tradeoffs**, plus exact citations and any code snippet worth quoting.

### Agent: Overview & Architecture

Investigate:

- Entry points and bootstrapping/wiring code (exact file paths)
- The logical layers of the system (e.g. UI / Service / Model / Infrastructure, or Handler / Domain / Repository)
- For each layer: key files, defining interfaces or base classes, how it communicates with adjacent layers
- The 5-10 most important types, classes, and interfaces — what invariants do they enforce?
- Component dependency map: for each major component, what does it depend on and what depends on it?
- **The architectural style and why it was chosen.** Is it layered, hexagonal, event-driven, modular monolith, microservices? What alternative styles would have fit, and why does this one suit the project's scale, team, and domain? What does it cost?
- For each major structural boundary, apply the Decision Lens: why is the seam drawn here and not elsewhere?

### Agent: Data Flow & Lifecycles

Pick the 2-3 most important operations and trace each completely:

- Start from where it enters the process (HTTP handler, CLI args, queue consumer, event listener)
- Follow through every layer: routing, validation, business logic, persistence, response
- Note every file and function touched, every state mutation, every async boundary, every error branch
- Identify where the "interesting" logic lives vs. where it's just plumbing
- Find any retry logic, circuit breakers, or distributed coordination
- **Apply the Decision Lens to the flow shape itself:** why is this synchronous vs. async, why is work split across these steps, why this ordering, why this consistency model? What would a simpler or different design look like and what would it sacrifice?

### Agent: API / CLI / Extension Points

Investigate the full public interface surface:

- Every route, endpoint, command, or plugin hook with exact registration file and line
- Handler signatures, middleware chain order, auth patterns
- Request/response shapes — look at the actual TypeScript types, Go structs, Pydantic models, etc.
- Which handler calls which service
- Error handling and status code conventions at the boundary
- Rate limiting, pagination, versioning if present
- **Apply the Decision Lens:** why this API style (REST / GraphQL / gRPC / RPC)? Why this auth scheme over alternatives? Why these resource boundaries? Where the design deviates from convention, dig into why.

### Agent: Database & Data Models

This page must be a true data-model deep dive. Investigate:

- Schema definitions — ORM models, migration files, raw SQL schemas
- Every entity/table/collection: fields, types, constraints, indexes, defaults
- **The full relationship graph** between entities: one-to-one, one-to-many, many-to-many, polymorphic, self-referential. For each relationship, capture cardinality, the FK direction, and on-delete/on-update behavior.
- **For each entity and each relationship, apply the Decision Lens:**
  - Why does this entity exist as its own table vs. being embedded/denormalized into another?
  - Why is the data modeled this way (normalized vs. denormalized) and what does it trade off (write complexity vs. read performance, consistency vs. duplication)?
  - Why this relationship shape — e.g. why a join table instead of an array column, why a nullable FK, why a soft-delete flag instead of a hard delete?
  - What alternative data models were possible and why this one fits the access patterns?
- Key queries and access patterns — find the hot paths in services/repositories and tie each back to the indexes that support it.
- Index rationale: for every non-PK index, why does it exist (which query), and what does it cost on writes?
- Choice of datastore itself: why this database engine (Postgres / MySQL / Mongo / DynamoDB / etc.)? What does the data shape and access pattern demand, and what alternatives were viable?
- Migration strategy, notable schema evolution, and any backward-compatibility constraints
- N+1 risks, hot rows, and consistency/transaction boundaries

Return enough to build: a full ER diagram, a per-entity spec, and a per-relationship rationale.

### Agent: Core Services & Domain Logic

Investigate the business logic layer:

- What are the core service/module files?
- What business rules do they enforce? (Be specific — name the rules and the code that enforces them)
- How do services interact with each other?
- Are there interesting patterns: event sourcing, CQRS, saga, strategy, repository, etc.?
- Where are the domain boundaries drawn?
- **Apply the Decision Lens to each pattern and boundary:** why this pattern here, what simpler approach was rejected and why, and what the pattern costs in indirection or complexity. Why are the domain seams placed where they are?

### Agent: Performance, Memory & Techniques

This page must read like a performance engineering deep dive. For each technique, go far beyond naming it.

Hunt for:

- Caching layers: where, what's cached, TTL, eviction strategy, cache key construction, invalidation strategy
- Lazy initialization, object pooling, connection pool config and sizing
- Memoization, batching, debouncing, throttling, coalescing implementations
- Streaming vs. buffering decisions; backpressure handling
- Non-obvious data structures (tries, bloom filters, ring buffers, skip lists, etc.)
- Lock-free patterns, concurrency primitives, worker pools, sharding
- Memory layout tricks: pooling, arenas, struct-of-arrays, zero-copy, interning
- Any code comments referencing papers, blog posts, or benchmarks
- Benchmark files, perf test suites, or profiling scripts

**For each technique, produce a full breakdown:**

1. **The main trick** — precisely what it does, with file/function/line and a quoted code snippet.
2. **Why** — what performance or memory problem forced it; what the hot path or bottleneck was.
3. **How it works** — the mechanism in enough depth that a reader could reimplement it.
4. **Alternatives** — other techniques that solve the same problem and why this one was chosen.
5. **Related techniques** — adjacent or complementary optimizations worth knowing.
6. **Cost/tradeoff** — added complexity, memory overhead, staleness, correctness risk.
7. **Useful links** — **at least 5** authoritative external references per technique, following the Reference Standard below.

If the codebase has measured numbers (benchmark output, profiling results, comments citing latencies), capture them.

## The Reference Standard (apply to every component)

Every non-trivial component, technique, or concept must link to **at least 5 high-quality external references** so a junior reader can go learn more. Quality and source ranking matter:

**Prefer, in this order:**

1. **Official documentation** for the language, runtime, framework, or library involved (e.g. the Go spec, PostgreSQL docs, React docs, Redis docs, MDN for web APIs).
2. **Engineering blogs and papers from major tech companies** (e.g. Google, Meta, Netflix, Cloudflare, Uber, Discord, Stripe, AWS, Microsoft engineering blogs; published papers and design docs).
3. **Well-regarded independent technical writing** (e.g. authoritative personal/expert blogs, conference talks, established sites like the PostgreSQL wiki, Brendan Gregg's site, Martin Fowler's site).
4. **Wikipedia — only as a last resort**, and only to round out the list when you genuinely cannot find 5 better sources. Never let Wikipedia be the _primary_ or only reference for a concept.

**Rules:**

- Each reference must be specific and relevant — link the exact doc page or article about _this_ technique, not a generic homepage.
- Cover both the technique itself _and_ its main alternatives, so the reader can compare.
- Briefly annotate each link (one short phrase) saying what the reader will get from it.
- Do not fabricate URLs. Only link to pages you are confident exist; prefer stable, canonical URLs (official docs, well-known blogs). If unsure a specific deep link is valid, link the known-stable parent doc page instead.

Render reference lists clearly, e.g.:

```html
<ul class="ref-list">
  <li>
    <a href="https://go.dev/ref/spec#Slice_expressions"
      >Go spec — slice expressions (the 3-index form)</a
    >
    — official definition of <code>a[low:high:max]</code>.
  </li>
  <li>
    <a href="https://go.dev/blog/slices-intro"
      >Go blog — Go slices: usage and internals</a
    >
    — how slices, length, and capacity actually work.
  </li>
  <li><a href="...">...</a> — ...</li>
</ul>
```

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

Every research agent must also gather references: instruct each agent to collect, for every component or technique it reports, **at least 5 candidate reference links** following the Reference Standard (official docs first, big-tech engineering blogs and papers next, Wikipedia only as a last resort). Agents should return the exact URLs with a one-line note on what each covers.

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
  flowchart TD A[ChatWidget] --> B[IChatService] B --> C[ChatModel] B -->
  D[ModelRouter] D --> E[OpenAI API] D --> F[Anthropic API]
</div>
```

**Request lifecycle — sequence diagram:**

```html
<div class="mermaid">
  sequenceDiagram participant C as Client participant R as Router participant S
  as OrderService participant DB as Database C->>R: POST /orders R->>S:
  placeOrder(dto) S->>DB: INSERT order DB-->>S: order row S-->>R: OrderResult
  R-->>C: 201 Created
</div>
```

**Database schema — ER diagram:**

```html
<div class="mermaid">
  erDiagram USER ||--o{ ORDER : places ORDER ||--|{ LINE_ITEM : contains PRODUCT
  ||--o{ LINE_ITEM : "included in" ORDER { uuid id PK uuid user_id FK string
  status timestamp created_at }
</div>
```

**Class / interface relationships — class diagram:**

```html
<div class="mermaid">
  classDiagram class IChatService { +sendMessage(req) Response +getSession(id)
  Session } class ChatService { -sessionStore SessionStore -modelRouter
  ModelRouter +sendMessage(req) Response } IChatService <|.. ChatService
  ChatService --> SessionStore ChatService --> ModelRouter
</div>
```

**State machine — state diagram:**

```html
<div class="mermaid">
  stateDiagram-v2 [*] --> Pending Pending --> Processing: job picked up
  Processing --> Complete: success Processing --> Failed: error Failed -->
  Pending: retry (max 3) Failed --> Dead: retries exhausted
</div>
```

**CI/CD pipeline or multi-step process — graph:**

```html
<div class="mermaid">
  graph LR Lint --> Test Test --> Build Build --> Push["Push Image"] Push -->
  Deploy["Deploy Staging"] Deploy --> Smoke["Smoke Tests"] Smoke -->
  Prod["Deploy Prod"]
</div>
```

Use diagrams to show structure and flow, then prose to explain the _why_.
Never place a diagram without at least a paragraph before it setting context.

### The Decision Box Component

Use this for every Decision Lens analysis. It is the visual backbone of the deep-dive.

```html
<div class="decision-box">
  <div class="decision-title">
    Why an outbox table instead of publishing to SQS directly?
  </div>
  <div class="decision-row">
    <span class="decision-label what">What</span>
    <div>
      <code>OrderService.placeOrder()</code> inserts an <code>outbox</code> row
      in the same transaction as the order, and a poller relays it to SQS.
      <span class="source-ref">src/services/order.ts:150</span>
    </div>
  </div>
  <div class="decision-row">
    <span class="decision-label why">Why</span>
    <div>
      Guarantees the event is never lost if the process crashes after commit but
      before publish (the dual-write problem).
    </div>
  </div>
  <div class="decision-row">
    <span class="decision-label alt">Alternatives</span>
    <div>
      Direct publish after commit (simpler, but loses events on crash); 2-phase
      commit across DB and SQS (not supported by SQS); CDC via Debezium (heavier
      infra).
    </div>
  </div>
  <div class="decision-row">
    <span class="decision-label fit">Fit</span>
    <div>
      The team already runs Postgres and wants exactly-once delivery without new
      infrastructure; a poller is cheap at this scale.
    </div>
  </div>
  <div class="decision-row">
    <span class="decision-label cost">Tradeoff</span>
    <div>
      Adds polling latency and an extra table; requires a cleanup job for
      relayed rows.
    </div>
  </div>
</div>
```

Label classes: `what`, `why`, `alt`, `fit`, `cost`. Omit rows you genuinely cannot fill, but never omit `why`.

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

Write a deep technical specification that a **junior engineer in their first week** can actually follow — detailed and rigorous, but explained from the ground up. The depth is for a senior; the _clarity_ is for an intern. Both must hold at once.

**Required for every page:**

- Apply the **Audience Lens**: define every term the first time it's used, spell out symbols and expressions, explain mechanisms (never just labels), and build up from the concrete problem. No unexplained jargon — ever.
- Apply the **Reference Standard**: every non-trivial component or technique gets **at least 5** quality external links (official docs and big-tech blogs/papers first, Wikipedia last), each briefly annotated.
- Apply the **Decision Lens** to every significant element: what / why / alternatives / fit / tradeoffs. Use `decision-box` components for this.
- Open each major section with a paragraph explaining context and motivation before any code or diagrams
- Cite actual file paths and function/class names (and line numbers where useful) for every significant claim
- Quote real code snippets from the source for the important mechanisms — don't paraphrase
- Use Mermaid diagrams to visualize structure, flow, and relationships
- Use callout boxes for gotchas, non-obvious behavior, and important warnings
- Clearly distinguish documented fact from your own inference (e.g. "The code does X. _Likely rationale:_ ...")
- Connect to other pages where relevant

**Strictly avoid:**

- **Unexplained jargon** — any term, abbreviation, or symbol used without a plain-language definition the first time it appears
- **Label-as-explanation** — calling something "cache-friendly", "lock-free", or "zero-copy" without explaining the underlying mechanism in everyday terms
- Dense, multi-clause sentences that stack several unfamiliar nouns together
- Reference lists with fewer than 5 links, or that lean on Wikipedia as the primary source
- Stating _what_ without _why_ for any non-trivial choice
- Bullet-point-only sections with no narrative
- Generic statements that could describe any codebase
- Diagrams without surrounding prose
- Sections that restate what's already covered on another page
- Filler reasoning — if you don't know the why and can't reasonably infer it, say so

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
- **A `decision-box` for the overall architectural style** (why layered/hexagonal/event-driven, what was rejected, why it fits) and one for each major structural seam

**`data-flow.html` - Data Flow:**

- One Mermaid sequence diagram per traced operation
- Step-by-step narrative for each operation, citing every file and function
- Callout boxes for error paths, retry logic, and async boundaries
- State mutation map: what data changes at each step
- A `decision-box` for the flow's shape (sync vs async, consistency model, why split this way)

**`api.html` - API / CLI:**

- Full endpoint/command table: method, path, auth, handler file, description
- Mermaid sequence diagram for each key endpoint's handler flow
- Request/response type definitions as code blocks from actual source
- Auth and middleware chain explanation with a Mermaid diagram
- A `decision-box` for the API style and auth scheme choices

**`database.html` - Database (data-model deep dive):**

- Mermaid ER diagram covering the full schema with cardinalities
- A `decision-box` for the datastore choice itself (why this engine)
- **Per-entity section:** fields table (name / type / constraints / default), what the entity represents, and a `decision-box` explaining why it's modeled this way (normalized vs. denormalized, why separate table vs. embedded)
- **Per-relationship explanation:** for each edge in the ER diagram, state cardinality, FK direction, on-delete behavior, and a `decision-box` for why the relationship is shaped this way (e.g. join table vs. array, nullable FK, soft delete)
- Key queries as actual SQL or ORM code lifted from source, each tied to the index that serves it
- Index rationale table (index / columns / which query / write cost)
- Migration strategy and schema evolution decisions

**`services.html` - Services:**

- Per-service section: purpose, public interface, business rules, dependencies
- Mermaid flowcharts for complex business logic (especially branching flows)
- A `decision-box` for each notable design pattern (why this pattern, what was rejected, what it costs)

**`performance.html` - Performance (engineering deep dive):**
For each optimization, a full breakdown using a `technique-card` immediately followed by a `decision-box`:

- **The main trick** — what it is, explained from the ground up (define the jargon, walk through any code expression symbol by symbol), with a quoted code snippet and file/function citation
- **Why** — the bottleneck or memory pressure that forced it, in concrete terms
- **How it works** — enough mechanism detail to reimplement, with the _why behind the why_ (e.g. explain cache lines when you say "cache-friendly")
- **Alternatives** — other techniques for the same problem and why this one won
- **Related techniques** — complementary optimizations worth knowing
- **Tradeoff** — complexity, memory, staleness, correctness risk
- **Useful links** — **at least 5** references per the Reference Standard (official docs and big-tech engineering blogs/papers first, Wikipedia last), each annotated
  Also include: Mermaid diagrams for cache topology or batching pipelines, any benchmark/profiling numbers found in source, and a section on known bottlenecks.

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
- **Every non-trivial design choice has a `decision-box` with a real `why` — not just `what`**
- **Every jargon term, abbreviation, and code expression is defined in plain language the first time it appears** (read each page as if you were an intern — flag anything you couldn't follow)
- **Every non-trivial component or technique has at least 5 quality reference links, with Wikipedia only as a last resort, not the primary source**
- **No "label-as-explanation"** — terms like cache-friendly / lock-free / zero-copy are backed by a mechanism explanation
- **The database page explains every entity and every relationship's rationale, not just its shape**
- **The performance page gives each technique the full breakdown (why / how / alternatives / related / tradeoff / 5+ links)**
- Inference is clearly labeled as inference, not stated as fact
- No page has bullet-only sections — every list has surrounding prose
- Cross-page links use relative paths (`architecture.html`, not `/architecture.html`)
- Footer on every page shows project name and generation date
- ER diagram covers all entities found during research

---

## Large Codebases

For very large pages, generate in chunks to avoid context pressure:

1. Write the HTML shell, sidebar, and hero for the page first
2. Add sections in batches of 2-3, using Edit to append before `</main>`
3. Each batch should be self-contained prose + diagram units

After all pages exist, do one final pass to add cross-links between them.
