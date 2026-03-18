/**
 * PAI Installer v4.0 — System Detection
 * Detects OS, tools, existing PAI installation, and environment.
 * All detection is read-only and non-destructive.
 */

import { execSync } from "child_process";
import { existsSync, readFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";
import type { DetectionResult } from "./types";

function tryExec(cmd: string): string | null {
  try {
    return execSync(cmd, { timeout: 5000, stdio: ["pipe", "pipe", "pipe"] })
      .toString()
      .trim();
  } catch {
    return null;
  }
}

function commandExists(name: string): string | null {
  if (process.platform === "win32") {
    return tryExec(`where ${name}`)?.split(/\r?\n/)[0] || null;
  }
  return tryExec(`which ${name}`);
}

function detectOS(): DetectionResult["os"] {
  const platform = process.platform === "darwin"
    ? "darwin"
    : process.platform === "win32"
      ? "win32"
      : "linux";
  const arch = process.arch;

  let version = "";
  let name = "";

  if (platform === "darwin") {
    version = tryExec("sw_vers -productVersion") || "";
    name = `macOS ${version}`;
  } else if (platform === "win32") {
    version = tryExec('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Version"') || "";
    const caption = tryExec('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption"') || "Windows";
    name = caption;
  } else {
    const release = tryExec("grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2");
    name = release || "Linux";
    version = tryExec("uname -r") || "";
  }

  return { platform, arch, version, name };
}

function detectShell(): DetectionResult["shell"] {
  if (process.platform === "win32") {
    const shellPath = process.env.ComSpec || "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe";
    const version = tryExec('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') || "";
    return { name: "powershell", version, path: shellPath };
  }

  const shellPath = process.env.SHELL || "/bin/sh";
  const shellName = shellPath.split("/").pop() || "sh";
  const version = tryExec(`${shellPath} --version 2>&1 | head -1`) || "";

  return { name: shellName, version, path: shellPath };
}

function detectTool(
  name: string,
  versionCmd: string
): { installed: boolean; version?: string; path?: string } {
  const path = commandExists(name);
  if (!path) return { installed: false };

  const versionOutput = tryExec(versionCmd);
  const versionMatch = versionOutput?.match(/(\d+\.\d+[\.\d]*)/);
  const version = versionMatch?.[1] || versionOutput || undefined;

  return { installed: true, version, path };
}

function detectExisting(
  home: string,
  paiDir: string,
  configDir: string
): DetectionResult["existing"] {
  const result: DetectionResult["existing"] = {
    paiInstalled: false,
    hasApiKeys: false,
    elevenLabsKeyFound: false,
    backupPaths: [],
  };

  const settingsPath = join(paiDir, "settings.json");
  if (existsSync(settingsPath)) {
    result.paiInstalled = true;
    result.settingsPath = settingsPath;

    try {
      const settings = JSON.parse(readFileSync(settingsPath, "utf-8"));
      result.paiVersion = settings.pai?.version || settings.paiVersion || "unknown";
    } catch {
      result.paiVersion = "unknown";
    }
  }

  if (existsSync(join(paiDir, "skills", "PAI", "SKILL.md"))) {
    result.paiInstalled = true;
  }

  const envPath = join(configDir, ".env");
  if (existsSync(envPath)) {
    try {
      const envContent = readFileSync(envPath, "utf-8");
      result.elevenLabsKeyFound = envContent.includes("ELEVENLABS_API_KEY=");
      result.hasApiKeys = result.elevenLabsKeyFound;
    } catch {
      // Permission denied or other error
    }
  }

  const backupPatterns = [
    join(home, ".claude-backup"),
    join(home, ".claude-old"),
    join(home, ".claude-BACKUP"),
  ];
  for (const bp of backupPatterns) {
    if (existsSync(bp)) {
      result.backupPaths.push(bp);
    }
  }

  return result;
}

export function detectSystem(): DetectionResult {
  const home = homedir();
  const paiDir = join(home, ".claude");
  const configDir = process.env.PAI_CONFIG_DIR || (process.platform === "win32"
    ? join(home, ".claude", "config", "PAI")
    : join(home, ".config", "PAI"));

  return {
    os: detectOS(),
    shell: detectShell(),
    tools: {
      bun: detectTool("bun", "bun --version"),
      git: detectTool("git", "git --version"),
      claude: detectTool("claude", "claude --version 2>&1"),
      node: detectTool("node", "node --version"),
      brew: {
        installed: commandExists("brew") !== null,
        path: commandExists("brew") || undefined,
      },
    },
    existing: detectExisting(home, paiDir, configDir),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    homeDir: home,
    paiDir,
    configDir,
  };
}

export async function validateElevenLabsKey(key: string): Promise<{ valid: boolean; error?: string }> {
  try {
    const res = await fetch("https://api.elevenlabs.io/v1/voices", {
      headers: { "xi-api-key": key },
      signal: AbortSignal.timeout(10000),
    });

    if (res.ok) return { valid: true };

    if (res.status === 401) {
      try {
        const body = await res.json();
        if (body?.detail?.status === "missing_permissions") {
          return { valid: true };
        }
      } catch { }
    }

    return { valid: false, error: `HTTP ${res.status}` };
  } catch (e: any) {
    return { valid: false, error: e.message || "Network error" };
  }
}
