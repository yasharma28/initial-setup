# Self-Documenting Docs Stack — Build Plan & Handoff

> Handoff doc for continuing this work in a fresh agent session. Everything decided
> so far is captured here; the schemas in this folder are validated and ready to use.

---

## 1. Goal

Build an **open-source** tool for **self-updating codebase documentation** across an
org with **100+ GitHub repos** (Go, Python, TypeScript, Rust, Terraform), CI on
**GitHub Actions**. Two needs:

1. **Repo-level** docs that help new devs understand a repo's architecture, APIs, and
   style — generated and kept fresh on every merge.
2. **Org-level** centralized, searchable place across all repos — for cross-team
   discovery and incident response.

Both must **update on merge to main** so docs never go stale.

## 2. Hard constraints

- **Free + self-hostable.** Source code must stay in our infra.
- LLM API calls are **sanctioned** (org has Claude Enterprise; route via Bedrock/Vertex
  to keep data in-tenant). So the LLM step is allowed — it is not the bottleneck.
- **Reuse OSS aggressively.** Do not reinvent. Build only glue + the contracts.

## 3. Finalized architecture — two deliverables, one contract

See `diagrams/architecture.mermaid.md` (and `.ascii.txt`, `.excalidraw.md`).

### Deliverable 1 — Repo Generator (the OSS tool's core)
- A **Go CLI** (also usable as a Claude Code / OpenCode **Skill**).
- Runs in CI **on merge to main** (path-filtered).
- Emits **Markdown into the repo's `/docs`** + a **`manifest.json`**.
- **Divio** is the default `--profile` (repo-level only; pluggable, not mandated).
- Generation layers:
  - **Reference (Divio 30-39) = HERMETIC.** Deterministic, from language-native tools
    (`godoc`, `pdoc`, `TypeDoc`, `rustdoc`, `terraform-docs`) + `codebase-memory-mcp`
    `search_graph`. Same inputs → same bytes.
  - **Explanation (10-19) = NON-HERMETIC (LLM).** `codebase-memory-mcp.get_architecture`
    → LLM writes architecture narrative + Mermaid diagrams. Model + temp 0 + prompt
    pinned; treated as regenerate-and-review, gated by drift.
  - **Tutorials (00-09), How-to (20-29), Troubleshooting (99)** = scaffolded stubs /
    human-authored. Generator **never overwrites** `authored: human` docs.

### Deliverable 2 — Org Search App
- **Self-hostable, CONSUME-ONLY — it never generates.** (This is the line that keeps us
  from rebuilding DeepWiki.)
- Ingests each repo's published `/docs` + `manifest.json` on merge (webhook/poll).
- **DB-backed index** (start with embedded **SQLite FTS5 + sqlite-vec**; graduate to
  **Meilisearch** if relevance demands). Index = a **derived cache**, fully rebuildable
  from the repos → the hermetic projection.
- Serves cross-repo search + browse for onboarding and incident response.

### The seam — `manifest.json`
One contract read by **all** consumers: publish adapters, the drift check, and the org
app's ingest (`docs[]` is literally the ingestion API). Schema in `schemas/`.

## 4. The contracts (validated, in this folder)

| File | What |
|------|------|
| `schemas/manifest.schema.json` | Output contract emitted per repo. JSON Schema 2020-12. |
| `schemas/manifest.example.json` | Validated example instance. |
| `schemas/docgen.schema.json` | Input contract: `docgen.yaml` config. |
| `examples/docgen.org-base.yaml` | Org-wide base config (the DRY `extends` target). |
| `examples/docgen.yaml` | Per-repo config that `extends` the base. |

### manifest.json key fields (the design that matters)
- `covers[]` per doc = **Bazel-style dependency edges** back to code (symbol/package/
  route/path). On merge: intersect changed nodes with each doc's `covers[]` → only
  intersecting docs are stale. **Exact incremental invalidation**, no semantic guessing.
- `hermetic` + `inputsHash` per doc = the **build cache key**. Equal `inputsHash` ⇒ skip
  regeneration. Quarantines the non-deterministic LLM layer.
- `authored: generated | stub | human` = the **never-overwrite-humans latch**.
- `generator.render` + `generator.llm` + `toolchain` = **provenance**; these are inputs,
  so they feed `inputsHash` (changing the Mermaid palette correctly busts the cache).

### docgen.yaml key design
- `extends:` = the **DRY lever** — set palette / model / quadrant policy ONCE org-wide;
  repos override only deltas. **Pin the ref** when extending.
- Resolution order: built-in defaults < org base (`extends`) < repo file < CLI flags.
- **Secrets are env-only** (`llm.apiKeyEnv` names the env var; the key is never in the
  committed file). Schema has no field to hold a raw key, on purpose.
- `render` supports colorblind-safe Mermaid (`palette: okabe-ito`) and multiple diagram
  formats (`mermaid`, `plantuml`, `d2`, `ascii`) — per-doc renditions in `diagrams[]`.

## 5. The Bazel / hermetic mental model (and where it breaks)

The system is a build tree for docs — but **only partly hermetic**:
- **Reference layer** = truly hermetic (pin tool versions → reproducible). ✅
- **Explanation layer** = LLM, **non-deterministic** — regenerate-and-review, not
  byte-reproducible. Pin model + temp 0 + prompt to get as close as a provider allows.
- **Tutorials/how-tos** = checked-in human source, not build artifacts.
- Dependency edges are explicit via `covers[]` (not BUILD files) → exact invalidation.

## 6. Reuse strategy / what NOT to build

| Need | Reuse (OSS) | Build |
|------|-------------|-------|
| Code structure | `codebase-memory-mcp` (already in use) | — |
| Reference docs | godoc · pdoc · TypeDoc · rustdoc · terraform-docs | profile mapping |
| Architecture prose | LLM provider SDKs (BYO key) | the pinned prompt |
| Diagrams | Mermaid (renderer is OSS) | prompt → mermaid |
| Org search | SQLite FTS5 + sqlite-vec / Meilisearch | ingest + schema |
| Org UI | off-the-shelf search UI / docs theme | thin wiring |
| **Glue + 2 contracts** | — | **this is the actual product** |

**DeepWiki-Open: studied, NOT adopted.** It is a vertically-integrated generate-and-serve
web app — the opposite of our generate-then-index split, and it ignores Divio / git-native
docs / generate-once. Reuse its *ideas* (chunking, diagram prompting), not the app.
We already have a *more precise* structure source than its RAG: the real call graph.

## 7. Language decision
- **Go** = primary (single static binary, zero-dep Docker, matches `codebase-memory-mcp`).
- **TypeScript** = alternative only if the Claude-Code-plugin/MCP-SDK angle is top priority.
- Not Rust (I/O-bound on LLM + subprocess; no benefit). Python only if team is Python-first.
- Note: the generator shells out to language-native doc tools, so the orchestrator language
  is decoupled from the languages it documents → pick for distribution = Go.

## 8. Build sequence (recommended next steps)

1. **Scaffold the repo**: Go module, commit the two schemas + example configs from this
   folder, a `docs/` Divio profile, stub `docgen generate`.
2. **Prove Layer 1 on ONE repo, Reference quadrant first** (deterministic, no LLM key):
   `codebase-memory-mcp` + language-native tools → `30-api-reference.md` + `manifest.json`.
3. **Add the LLM Explanation step** (architecture.md + Mermaid), pinned, writing the
   `hermetic:false` docs.
4. **Add `docgen drift`** (PR check) using `manifest.covers[]`.
5. **Then Deliverable 2**: consume-only ingest + SQLite FTS5 search over a few repos.
6. Wire the GitHub Actions workflow (on push:main, path-filtered) + a publish adapter.

## 9. Open decisions to confirm
- **`extends` merge semantics:** currently **shallow per-section override** (overriding
  `render` replaces the whole block). Decide if **deep merge** (override just
  `render.mermaid.palette`) is wanted — it changes resolution logic.
- **Org search backend:** SQLite FTS5+sqlite-vec (single-container simple) vs Meilisearch
  (better relevance, extra service). Recommend starting SQLite.
- **Diagram formats to ship first:** mermaid (+ ascii for incident CLI). plantuml/d2 later.
- **Cache-bust cost:** changing an org-wide render/prompt/model input regenerates all
  100+ repos on next merge. Schedule deliberately.

## 10. Provenance
Designed across a planning session (≈2026-06-25). Schemas here are validated (structural +
JSON parse). The `.excalidraw.md` board opens in Obsidian with the Excalidraw plugin.
