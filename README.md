# luxlike-agent

Monorepo scaffold for a Roblox plugin plus a Vercel serverless API.

## Project structure

- `vercel-api/` - Vercel Serverless Function backend
- `roblox-plugin/` - Roblox plugin codebase (placeholder)

## Vercel API

Endpoint file:

- `vercel-api/api/agent.ts`

### Local payload contract

`POST /api/agent` expects JSON:

```json
{
  "projectName": "string",
  "prompt": "string",
  "files": []
}
```

Success response format:

```json
{
  "summary": "string",
  "plan": ["string"],
  "changes": [],
  "warnings": []
}
```

## Deploy to Vercel

1. Install CLI: `npm i -g vercel`
2. Move into the API folder: `cd vercel-api`
3. Login: `vercel login`
4. Deploy preview: `vercel`
5. Deploy production: `vercel --prod`

After deploy, the function is available at `/api/agent` on your Vercel project domain.

## Environment variables (for later)

No env vars are required for the current test response.

When AI integration is added, set env vars in:

- Vercel Dashboard -> Project -> Settings -> Environment Variables
- or CLI, for example: `vercel env add OPENAI_API_KEY production`

Recommended future vars:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`
