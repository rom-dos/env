// OpenCode plugin: Initialize session state and environment
// Runs on session.created event

import type { Plugin, PluginInput } from "@opencode-ai/plugin";
import { existsSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";
import { homedir } from "os";

function getLocalTimestamp(): string {
  const date = new Date();
  const tz =
    process.env.TIME_ZONE || Intl.DateTimeFormat().resolvedOptions().timeZone;

  try {
    const localDate = new Date(date.toLocaleString("en-US", { timeZone: tz }));
    const year = localDate.getFullYear();
    const month = String(localDate.getMonth() + 1).padStart(2, "0");
    const day = String(localDate.getDate()).padStart(2, "0");
    const hours = String(localDate.getHours()).padStart(2, "0");
    const minutes = String(localDate.getMinutes()).padStart(2, "0");
    const seconds = String(localDate.getSeconds()).padStart(2, "0");

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  } catch {
    return new Date().toISOString();
  }
}

function getProjectName(cwd: string | undefined): string {
  if (!cwd) return "Session";

  // Extract project name from path
  const parts = cwd.split("/").filter((p) => p);

  // Look for common project indicators
  const projectIndicators = ["Projects", "projects", "src", "repos", "code"];
  for (let i = parts.length - 1; i >= 0; i--) {
    if (projectIndicators.includes(parts[i]) && parts[i + 1]) {
      return parts[i + 1];
    }
  }

  // Default to last directory component
  return parts[parts.length - 1] || "Session";
}

export const InitializeSessionPlugin: Plugin = async ({
  client,
  directory,
}: PluginInput) => {
  return {
    // Use generic event hook to listen for session.created
    event: async (input: { event: any }) => {
      // Only handle session.created events
      if (input.event.type !== "session.created") {
        return;
      }

      try {
        const paiDir = process.env.PAI_DIR || join(homedir(), ".claude");
        const sessionId = input.event.properties.info.id;
        const cwd = directory;

        // Get project name
        const projectName = getProjectName(cwd);

        // Ensure required directories exist
        const requiredDirs = [
          join(paiDir, "hooks", "lib"),
          join(paiDir, "history", "sessions"),
          join(paiDir, "history", "learnings"),
          join(paiDir, "history", "research"),
        ];

        for (const dir of requiredDirs) {
          if (!existsSync(dir)) {
            mkdirSync(dir, { recursive: true });
          }
        }

        // Create session marker file
        const sessionFile = join(paiDir, ".current-session");
        writeFileSync(
          sessionFile,
          JSON.stringify(
            {
              session_id: sessionId,
              started: getLocalTimestamp(),
              cwd: cwd,
              project: projectName,
            },
            null,
            2,
          ),
        );

        // Log session initialization
        await client.app.log({
          service: "initialize-session",
          level: "info",
          message: `Session initialized: ${projectName}`,
          extra: {
            session_id: sessionId,
            project: projectName,
            cwd: cwd,
            timestamp: getLocalTimestamp(),
          },
        });
      } catch (error) {
        // Never crash - just log
        await client.app.log({
          service: "initialize-session",
          level: "error",
          message: "Session initialization error",
          extra: {
            error: error instanceof Error ? error.message : String(error),
          },
        });
      }
    },
  };
};
