# hanzoai-fetch

The [Hanzo API](https://api.hanzo.ai) on the host's own `fetch`. Same document,
same 2479 operations across 192 products as [`hanzoai`](https://www.npmjs.com/package/hanzoai)
— generated from the OpenAPI description each subsystem's router emits, so it
cannot name an address the server does not serve — and **no dependencies at
all**.

## Which one you want

**Use `hanzoai`.** It is the default TypeScript client, it is what the docs and
examples are written against, and on Node and in a bundled browser app it is the
one to install.

**Use `hanzoai-fetch` when the host is the reason.** Three cases, and they are
the only ones:

- **You run where a dependency tree is the cost.** `hanzoai` depends on axios,
  and `npm i axios@^1.7.0` resolves 1.19.0 and installs **27 packages, 4.1 MB**
  — axios pulls `follow-redirects`, `form-data`, `https-proxy-agent` and
  `proxy-from-env`, and those pull twenty-two more. This package installs
  **zero**. On a Worker, a Deno isolate or a Bun process that difference is the
  whole build.
- **You need the `Response`.** Every operation has a `…Raw()` twin returning
  `{ raw, value }` where `raw` is the live `Response` — so `raw.body` is a
  `ReadableStream` and a streaming completion is readable without leaving the
  client.
- **You want the transport passed in, not configured.** `fetchApi` takes the
  host's fetch by value, which is what makes a test run with no network and no
  interceptor.

If none of those is true for you, `hanzoai` is the better package and this one
buys you nothing.

## Install

```bash
npm i hanzoai-fetch
```

Types are included. There is nothing else to install: `fetch`, `Response`,
`Headers` and `ReadableStream` are the host's, and every runtime this package
targets — Node 18+, Deno, Bun, Cloudflare Workers, every current browser — has
them.

## Quickstart

`GET /v1/models` is public, so this runs before you have a key:

```ts
import { Configuration, ModelsApi } from 'hanzoai-fetch';

const models = new ModelsApi(new Configuration({ basePath: 'https://api.hanzo.ai' }));

const { raw } = await models.getModelsRaw();
const catalog = (await raw.json()) as { data: Array<{ id: string }> };

console.log(`${catalog.data.length} models`);
for (const m of catalog.data.slice(0, 4)) console.log(`  ${m.id}`);
```

```
$ node quickstart.mjs
520 models
  ai21/jamba-large-1.7
  aion-labs/aion-2.0
  aion-labs/aion-3.0
  aion-labs/aion-3.0-mini
```

## Auth

One scheme: a bearer token — an IAM access token or a Cloud API key. The server
derives your org from the token's `owner` claim, so no route takes an org
argument.

It goes in `accessToken`. The document declares one `securityScheme` (`bearer`,
http/bearer) and applies it at the top level, so 2498 operations across 191 of
the 192 api classes read that field and send `Authorization: Bearer <token>`.

```ts
import { Configuration, ChatApi } from 'hanzoai-fetch';

const config = new Configuration({
  basePath: 'https://api.hanzo.ai',
  accessToken: process.env.HANZO_API_KEY,
});

const { raw } = await new ChatApi(config).postChatCompletionsRaw();
```

`accessToken` also takes a function, sync or async, which is how a short-lived
IAM token is refreshed without rebuilding the client:

```ts
new Configuration({ accessToken: async () => (await mintToken()).access_token });
```

Four operations opt out and take no credential: `GET /v1/models`,
`GET /v1/models/providers`, `GET /v1/commands`, `GET /v1/openapi.json`. With no
`accessToken` set the client sends no header at all.

## Streaming

The `…Raw()` twin hands back the `Response` before anything reads it, so a
server-sent stream is read as a stream:

```ts
const { raw } = await new ChatApi(config).postChatCompletionsRaw();

const reader = raw.body!.pipeThrough(new TextDecoderStream()).getReader();
for (;;) {
  const { value, done } = await reader.read();
  if (done) break;
  process.stdout.write(value);
}
```

## Bringing your own fetch

`fetchApi` replaces the transport for one client — a mock in a test, an
instrumented fetch in production, or a runtime whose fetch is not global:

```ts
const config = new Configuration({
  basePath: 'https://api.hanzo.ai',
  fetchApi: (url, init) => myFetch(url, init),
});
```

`middleware` is the other seat, for cross-cutting behaviour that is the same on
every call:

```ts
const config = new Configuration({
  middleware: [{
    pre: async ({ url, init }) => ({ url, init: { ...init, headers: { ...init.headers, 'x-request-id': id() } } }),
    onError: async ({ error }) => { report(error); },
  }],
});
```

## Where the code comes from

`src/` is generated, and nothing in it is edited by hand. `.spec-lock` names the
hanzoai/cloud commit and the sha256 of the `openapi.yaml` this tree is a
projection of; the driver is
[`hanzoai/openapi`](https://github.com/hanzoai/openapi)'s `generate.py`, and
every knob it uses is the `fetch` row of that repo's `sdks.yaml`.

```bash
OPENAPI=../../hanzo/openapi ./scripts/generate.sh            # regenerate src/
OPENAPI=../../hanzo/openapi ./scripts/generate.sh --check     # fail if src/ drifted
```

A cloud release regenerates every client in the fleet from one document at one
digest, so `hanzoai`, `hanzoai-fetch` and `hanzoai-angular` always describe the
same release.

## Build

```bash
npm ci
npm run build     # tsc (CJS) + tsc -p tsconfig.esm.json (ESM) → dist/
```

Both halves are published: `require('hanzoai-fetch')` gets `dist/`,
`import 'hanzoai-fetch'` gets `dist/esm/`. Relative imports carry `.js`, so the
ESM half loads in Node, Deno and a Worker rather than only in a bundler.

## License

Apache-2.0
