type AgentRequestBody = {
  projectName: string;
  prompt: string;
  files: unknown[];
};

type AgentResponse = {
  summary: string;
  plan: string[];
  changes: unknown[];
  warnings: string[];
};

function isValidBody(body: unknown): body is AgentRequestBody {
  if (typeof body !== "object" || body === null) {
    return false;
  }

  const candidate = body as Record<string, unknown>;

  return (
    typeof candidate.projectName === "string" &&
    typeof candidate.prompt === "string" &&
    Array.isArray(candidate.files)
  );
}

export default function handler(req: any, res: any) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed. Use POST." });
  }

  let body: unknown = req.body;

  if (typeof body === "string") {
    try {
      body = JSON.parse(body);
    } catch {
      return res.status(400).json({ error: "Invalid JSON body." });
    }
  }

  if (!isValidBody(body)) {
    return res.status(400).json({
      error:
        "Body must include projectName (string), prompt (string), and files (array).",
    });
  }

  const response: AgentResponse = {
    summary: `Test summary for ${body.projectName}`,
    plan: [
      "Validate input payload",
      "Return test response format",
      "Prepare for AI integration",
    ],
    changes: [],
    warnings: [],
  };

  return res.status(200).json(response);
}
