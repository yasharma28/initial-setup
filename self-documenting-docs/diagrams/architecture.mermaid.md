# Self-Documenting Docs Stack — Architecture (Mermaid)

Two deliverables sharing one contract (`manifest.json`). Render in any Mermaid viewer.

```mermaid
flowchart TD
    %% ---- PR + trigger ----
    PR[Developer opens PR] --> DRIFT[doc-gen drift check<br/>uses manifest covers:]
    DRIFT --> MERGE[Merge to main]
    MERGE --> GHA[GitHub Actions<br/>on push:main, path-filtered]

    %% ---- Deliverable 1: repo generator ----
    subgraph D1[DELIVERABLE 1 — Repo Generator: Go CLI / Skill, runs in CI, docs stay in repo]
        GHA --> ORCH[doc-gen CLI / Skill entrypoint]
        ORCH --> MCP[(reuse) codebase-memory-mcp → graph<br/>index / detect_changes]
        MCP --> REF[Reference 30-39 — HERMETIC<br/>godoc·pdoc·TypeDoc·rustdoc·terraform-docs<br/>same in → same out]
        MCP --> EXP[Explanation 10-19 — LLM<br/>provider SDK + get_architecture → Mermaid<br/>model pinned · temp 0 · drift-gated]
        MCP --> STUB[Scaffold stubs 00/20/99<br/>only if missing — never clobber human]
        MCP --> RULES[Divio profile flag<br/>+ WHY-comments + ordering]
        REF --> OUT
        EXP --> OUT
        STUB --> OUT
        RULES --> OUT
        OUT[OUTPUT CONTRACT — the seam<br/>/docs Markdown + manifest.json covers:]
        OUT -. covers: exact invalidation .-> MCP
        OUT -. optional .-> ADAPT[publish adapter → per-repo site / Pages]
    end

    %% ---- Deliverable 2: org search app ----
    subgraph D2[DELIVERABLE 2 — Org Search App: self-hostable, CONSUME-ONLY, never generates]
        OUT == manifest.json == ingest API ==> INGEST[Ingest on merge<br/>webhook / poll]
        INGEST --> DB[(reuse) Index DB<br/>SQLite FTS5 + sqlite-vec or Meilisearch]
        DB --> UI[Search + browse UI<br/>cross-repo · always current]
        UI --> DEVS[New devs: onboarding]
        UI --> INC[Incident: cross-team search]
    end

    %% ---- Local loop ----
    OUT -. reads same /docs .-> LOCAL[LOCAL DEV LOOP<br/>Claude Code / OpenCode + codebase-memory-mcp]

    %% ---- DeepWiki note ----
    DEEP[DeepWiki-Open — STUDIED, NOT ADOPTED<br/>reuse parts: chunking, diagram prompts<br/>not its generate+serve app]
    EXP -. ideas only .-> DEEP

    classDef build fill:#ffec99,stroke:#e8590c;
    classDef reuse fill:#a5d8ff,stroke:#1971c2;
    classDef hermetic fill:#d3f9d8,stroke:#2f9e44;
    classDef consume fill:#eebefa,stroke:#9c36b5;
    classDef seam fill:#ffe066,stroke:#f08c00;
    classDef note fill:#f1f3f5,stroke:#868e96;

    class ORCH,STUB,RULES,EXP,DRIFT,ADAPT,INGEST build;
    class MCP,DB,UI,LOCAL reuse;
    class REF hermetic;
    class DEVS,INC consume;
    class OUT seam;
    class DEEP note;
```

## Legend
- **Build (orange):** components to write.
- **Reuse (blue):** existing OSS — do not reinvent.
- **Hermetic (green):** byte-reproducible from pinned inputs.
- **Consumer (purple):** who uses the org app.
- **Seam (gold):** `manifest.json` — the single contract between deliverables.
- **Note (grey):** DeepWiki-Open — reference for ideas only, not a dependency.
