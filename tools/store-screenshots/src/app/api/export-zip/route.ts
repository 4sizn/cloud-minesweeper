import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

// Dev helper: the editor's "Export bundle" triggers a browser download, which a
// headless/embedded browser cannot save. This writes the same zip to disk instead.
export async function POST(req: Request) {
  const { base64 } = (await req.json()) as { base64?: string };
  if (!base64) return NextResponse.json({ ok: false, error: "Missing base64" }, { status: 400 });
  const file = path.join(process.cwd(), "export-bundle.zip");
  await fs.writeFile(file, Buffer.from(base64, "base64"));
  return NextResponse.json({ ok: true, file });
}
