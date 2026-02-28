type InputFile = {
  path: string;
  className?: string;
  source: string;
};

type AgentRequestBody = {
  projectName: string;
  prompt: string;
  files: InputFile[];
  capabilities?: Record<string, unknown>;
};

type AgentChange = {
  path: string;
  action: "replace_source";
  newSource: string;
};

type AgentResponse = {
  summary: string;
  plan: string[];
  changes: AgentChange[];
  warnings: string[];
};

const MAX_FILES = 30;
const MAX_SOURCE_LENGTH = 120000;
const MAX_PROMPT_LENGTH = 8000;
const DEFAULT_MODEL = "gpt-4.1-mini";

const SYSTEM_PROMPT = [
  "You are the backend model for Razon Agent.",
  "Return ONLY valid JSON. No markdown. No code fences. No prose outside JSON.",
  "Use this exact schema and no extra keys:",
  "{",
  '  "summary": "string",',
  '  "plan": ["string"],',
  '  "changes": [',
  "    {",
  '      "path": "string",',
  '      "action": "replace_source",',
  '      "newSource": "string"',
  "    }",
  "  ],",
  '  "warnings": ["string"]',
  "}",
  "Rules:",
  '- "action" must always be "replace_source".',
  '- Every "changes[].path" must match one of the input files paths exactly.',
  "- No additional keys at any level.",
].join("\n");

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasOnlyKeys(
  obj: Record<string, unknown>,
  allowed: readonly string[]
): boolean {
  const keys = Object.keys(obj);
  return keys.every((key) => allowed.includes(key));
}

function isValidInputFile(file: unknown): file is InputFile {
  if (!isPlainObject(file)) {
    return false;
  }

  if (typeof file.path !== "string" || typeof file.source !== "string") {
    return false;
  }

  if (
    typeof file.className !== "undefined" &&
    typeof file.className !== "string"
  ) {
    return false;
  }

  if (file.source.length > MAX_SOURCE_LENGTH) {
    return false;
  }

  return true;
}

function isValidBody(body: unknown): body is AgentRequestBody {
  if (!isPlainObject(body)) {
    return false;
  }

  if (
    typeof body.projectName !== "string" ||
    typeof body.prompt !== "string" ||
    !Array.isArray(body.files)
  ) {
    return false;
  }

  if (body.prompt.length > MAX_PROMPT_LENGTH || body.files.length > MAX_FILES) {
    return false;
  }

  if (
    typeof body.capabilities !== "undefined" &&
    !isPlainObject(body.capabilities)
  ) {
    return false;
  }

  return body.files.every(isValidInputFile);
}

function extractContentFromChatCompletion(payload: unknown): string | null {
  if (!isPlainObject(payload)) {
    return null;
  }

  const choices = payload.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    return null;
  }

  const firstChoice = choices[0];
  if (!isPlainObject(firstChoice)) {
    return null;
  }

  const message = firstChoice.message;
  if (!isPlainObject(message)) {
    return null;
  }

  return typeof message.content === "string" ? message.content : null;
}

function parseJson(text: string): unknown {
  return JSON.parse(text);
}

function isValidAgentResponseShape(value: unknown): value is AgentResponse {
  if (!isPlainObject(value)) {
    return false;
  }

  if (!hasOnlyKeys(value, ["summary", "plan", "changes", "warnings"])) {
    return false;
  }

  if (typeof value.summary !== "string") {
    return false;
  }

  if (!Array.isArray(value.plan) || !value.plan.every((item) => typeof item === "string")) {
    return false;
  }

  if (!Array.isArray(value.warnings) || !value.warnings.every((item) => typeof item === "string")) {
    return false;
  }

  if (!Array.isArray(value.changes)) {
    return false;
  }

  for (const change of value.changes) {
    if (!isPlainObject(change)) {
      return false;
    }

    if (!hasOnlyKeys(change, ["path", "action", "newSource"])) {
      return false;
    }

    if (
      typeof change.path !== "string" ||
      change.action !== "replace_source" ||
      typeof change.newSource !== "string"
    ) {
      return false;
    }
  }

  return true;
}

function filterInvalidPaths(
  response: AgentResponse,
  inputPaths: Set<string>
): AgentResponse {
  const filteredChanges: AgentChange[] = [];
  const warnings = [...response.warnings];

  for (const change of response.changes) {
    if (!inputPaths.has(change.path)) {
      warnings.push(`Dropped change for unmatched path: ${change.path}`);
      continue;
    }

    filteredChanges.push(change);
  }

  return {
    summary: response.summary,
    plan: response.plan,
    changes: filteredChanges,
    warnings,
  };
}

async function callOpenAI(body: AgentRequestBody): Promise<unknown> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error("Missing OPENAI_API_KEY");
  }

  const model = process.env.MODEL || DEFAULT_MODEL;

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: JSON.stringify({
            projectName: body.projectName,
            prompt: body.prompt,
            files: body.files,
            capabilities: body.capabilities ?? {},
          }),
        },
      ],
      temperature: 0,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${errorText}`);
  }

  return response.json();
}

export default async function handler(req: any, res: any) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed. Use POST." });
  }

  let body: unknown = req.body;

  if (typeof body === "string") {
    try {
      body = parseJson(body);
    } catch {
      return res.status(400).json({ error: "Invalid JSON body." });
    }
  }

  if (!isValidBody(body)) {
    return res.status(400).json({
      error:
        "Invalid request body. Expected projectName (string), prompt (<= 8000 chars), files (<= 30 items, each with path and source <= 120000 chars), and optional capabilities (object).",
    });
  }

  try {
    const completionPayload = await callOpenAI(body);
    const content = extractContentFromChatCompletion(completionPayload);
    if (typeof content !== "string") {
      return res.status(500).json({ error: "Invalid AI JSON" });
    }

    let parsed: unknown;
    try {
      parsed = parseJson(content);
    } catch {
      return res.status(500).json({ error: "Invalid AI JSON" });
    }

    if (!isValidAgentResponseShape(parsed)) {
      return res.status(500).json({ error: "Invalid AI JSON" });
    }

    const inputPaths = new Set(body.files.map((file) => file.path));
    const cleaned = filterInvalidPaths(parsed, inputPaths);
    return res.status(200).json(cleaned);
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to process request";
    return res.status(500).json({ error: message });
  }
}
