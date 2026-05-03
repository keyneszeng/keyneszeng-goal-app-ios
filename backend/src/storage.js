import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const dataDir = join(root, "data");
const runtimeDir = process.env.DATA_DIR ?? join(root, ".data");

function resolvePath(fileName) {
  return fileName === "checkins.json" ? join(runtimeDir, fileName) : join(dataDir, fileName);
}

export async function readJSON(fileName, fallback) {
  try {
    const raw = await readFile(resolvePath(fileName), "utf8");
    return JSON.parse(raw);
  } catch (error) {
    if (error.code === "ENOENT") return fallback;
    throw error;
  }
}

export async function writeJSON(fileName, value) {
  const raw = `${JSON.stringify(value, null, 2)}\n`;
  await mkdir(dirname(resolvePath(fileName)), { recursive: true });
  await writeFile(resolvePath(fileName), raw, "utf8");
}
