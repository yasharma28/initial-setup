# self-documenting-docs — plan & contracts

Design + validated contracts for an OSS self-updating codebase-documentation tool.
Handoff folder: pick up from **`PLAN.md`**.

## Contents

```
self-documenting-docs/
├── PLAN.md                          # START HERE — full build plan & decisions
├── schemas/
│   ├── manifest.schema.json         # OUTPUT contract (per-repo, JSON Schema 2020-12)
│   ├── manifest.example.json        # validated example instance
│   └── docgen.schema.json           # INPUT contract (docgen.yaml config)
├── examples/
│   ├── docgen.org-base.yaml         # org-wide base config (extends target)
│   └── docgen.yaml                  # per-repo config (extends the base)
└── diagrams/
    ├── architecture.mermaid.md      # pipeline as Mermaid
    ├── architecture.ascii.txt       # pipeline as ASCII
    └── architecture.excalidraw.md   # Obsidian Excalidraw board
```

## One-line model

A Go CLI/Skill that, on merge, generates static per-repo Divio Markdown + `manifest.json`
(Reference hermetic, Explanation LLM-pinned), consumed by a separate self-hostable,
consume-only org search app. Reuse OSS for every heavy part; build the glue + the two
contracts. `manifest.json` is the single seam.
