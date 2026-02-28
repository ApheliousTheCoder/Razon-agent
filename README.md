# Razon Agent

Monorepo scaffold for a Roblox plugin plus a Vercel serverless API.

## Project structure

- `vercel-api/` - Vercel Serverless Function backend
- `roblox-plugin/` - Roblox plugin codebase (placeholder)

## Vercel API

Endpoint file:

- `vercel-api/api/agent.ts`

### Request contract

`POST /api/agent` expects JSON:

```json
{
  "projectName": "string",
  "prompt": "string",
  "files": [
    {
      "path": "string",
      "className": "string (optional)",
      "source": "string"
    }
  ],
  "capabilities": {}
}
```

Validation limits:

- `prompt` max `8000` characters
- `files` max `30` entries
- each `files[i].source` max `120000` characters

### Response format

```json
{
  "summary": "string",
  "plan": ["string"],
  "changes": [
    {
      "path": "string",
      "action": "replace_source",
      "newSource": "string"
    }
  ],
  "warnings": ["string"]
}
```

## Environment variables (Vercel)

`OPENAI_API_KEY` is required.

`MODEL` is optional. If not set, the API defaults to `gpt-4.1-mini`.

Set variables in Vercel Dashboard:

1. Open your Vercel project.
2. Go to `Settings` -> `Environment Variables`.
3. Add `OPENAI_API_KEY` with your key value.
4. Optionally add `MODEL`.
5. Redeploy after saving.

You can also use CLI:

```bash
vercel env add OPENAI_API_KEY production
vercel env add MODEL production
```

## Deploy to Vercel

1. Install CLI: `npm i -g vercel`
2. Move into the API folder: `cd vercel-api`
3. Login: `vercel login`
4. Deploy preview: `vercel`
5. Deploy production: `vercel --prod`

After deploy, the function is available at `/api/agent` on your Vercel project domain.

## Test with curl

Replace `<YOUR_DOMAIN>` with your deployed domain (for example `https://your-project.vercel.app`).

```bash
curl -X POST "<YOUR_DOMAIN>/api/agent" \
  -H "Content-Type: application/json" \
  -d '{
    "projectName": "Razon Agent",
    "prompt": "Refactor this file to improve readability.",
    "files": [
      {
        "path": "src/Main.lua",
        "className": "Main",
        "source": "local Main = {}\\nreturn Main"
      }
    ],
    "capabilities": {
      "allowRefactor": true
    }
  }'
```
