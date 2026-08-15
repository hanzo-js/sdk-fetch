# hanzoai-fetch

**This repo holds no decisions. `src/` is generated and `.spec-lock` says from
what.**

One of three TypeScript projections of hanzoai/cloud's `openapi.yaml`:

| package | repo | generator | for |
|---|---|---|---|
| `hanzoai` | hanzoai/js-sdk | typescript-axios | **the default** — Node, bundled browser apps |
| `hanzoai-fetch` | hanzo-js/sdk-fetch | typescript-fetch | hosts where a dependency tree is the cost, and callers who need the `Response` |
| `hanzoai-angular` | hanzo-js/sdk-angular | typescript-angular | Angular DI, `HttpClient`, `Observable` |

All three are regenerated from ONE document at ONE digest by a cloud release,
so they never describe different releases.

## The rule that put this repo here

A variant earns a package when a **runtime or a framework cannot use the default
projection** — not when it would read differently. `hanzoai` already ships
`.d.ts` beside compiled CJS and ESM, so "plain JavaScript" and every bundler
flavour are its audience, not a second package's. The other eleven TypeScript
and JavaScript generators openapi-generator offers are refused in
`hanzoai/openapi`'s `sdks.yaml`, each with the audience it fails to have.

What this one has that the default cannot:

- **zero dependencies.** Measured: `npm i axios@^1.7.0` resolves 1.19.0 and
  installs 27 packages / 4.1 MB. This package installs 0.
- **the `Response`.** `…Raw()` returns `{ raw, value }`; `raw.body` is a
  `ReadableStream`, so a streaming completion is readable.
- **the transport by value.** `fetchApi` on the Configuration.

## Editing

Nothing under `src/`. To change what the client says, change the route in
hanzoai/cloud; to change how it is projected, change the **`fetch` row** of
`hanzoai/openapi`'s `sdks.yaml` and regenerate. `.generated` records every file
this driver wrote, and `--check` is what makes "nobody edited it" a fact.

```bash
OPENAPI=../../hanzo/openapi ./scripts/generate.sh --check   # clean, or the diff
```

Repo-owned (the generator never writes these): `package.json`, both tsconfigs,
`.spec-lock`, `hanzo.yml`, `scripts/`, `README.md`, `LICENSE`.

## Two things measured here, worth not re-learning

**`importFileExtension: .js` is load-bearing.** The generator writes relative
imports bare, which a bundler resolves and Node's ESM loader refuses —
`ERR_MODULE_NOT_FOUND` on `dist/esm/runtime`. That is the loader this package
exists for, so the row asks the generator for the extension; one value serves
both halves, because TypeScript emits the specifier verbatim. hanzoai/js-sdk has
the same hole and cannot close it — typescript-axios has no such property, which
is why its ESM output is bundler-only. `hanzo.yml` gates it by *importing* the
built client, since `tsc` cannot see this class of failure at all.

**`o11y.GettableAgentCheckIn` collides here and not in js-sdk.** It declares
`integration_config` **and** `integrationConfig`, `removed_at` **and**
`removedAt` — the snake spellings are live wire, kept so older AWS agents work.
typescript-axios declares a property under the document's own key, so the pairs
never meet; this generator camel-cases, so each pair is one property declared
twice (TS2300 + TS2717 + TS1117 + TS2559, nine errors). The row renames the
*identifier* and never the wire name — both keys still round-trip.

## Publishing

`npm publish` from the repo root, after `npm ci && npm run build`. Version lives
in `package.json` and the tag names it.
