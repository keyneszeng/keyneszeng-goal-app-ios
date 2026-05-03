import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { URL } from "node:url";
import { readJSON, writeJSON } from "./storage.js";

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";
const corsOrigin = process.env.CORS_ORIGIN ?? "*";

function sendJSON(response, status, body) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": corsOrigin,
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-headers": "content-type"
  });
  response.end(JSON.stringify(body));
}

function docs() {
  return {
    service: "kungfu-follow-backend",
    endpoints: [
      { method: "GET", path: "/health", description: "健康检查" },
      { method: "GET", path: "/api/routines", description: "获取功夫课程" },
      { method: "GET", path: "/api/checkins?userId=demo-user", description: "获取用户打卡历史" },
      { method: "POST", path: "/api/checkins", description: "提交打卡", body: { userId: "demo-user", routineId: "shaolin-foundation" } },
      { method: "GET", path: "/api/feed", description: "获取公开打卡动态" }
    ]
  };
}

function badRequest(response, message) {
  sendJSON(response, 400, { error: message });
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";
    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        request.destroy();
        reject(new Error("Request body too large"));
      }
    });
    request.on("end", () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch {
        reject(new Error("Invalid JSON body"));
      }
    });
    request.on("error", reject);
  });
}

function publicCheckIn(checkIn, routines) {
  const routine = routines.find((item) => item.id === checkIn.routineId);
  return {
    id: checkIn.id,
    userId: checkIn.userId,
    routineID: checkIn.routineId,
    routineTitle: routine?.title ?? checkIn.routineTitle ?? "功夫跟练",
    practicedAt: checkIn.practicedAt,
    minutes: routine?.duration ?? checkIn.minutes ?? 0
  };
}

async function handler(request, response) {
  if (request.method === "OPTIONS") {
    sendJSON(response, 204, {});
    return;
  }

  const requestURL = new URL(request.url ?? "/", `http://${request.headers.host}`);
  const path = requestURL.pathname;

  try {
    if (request.method === "GET" && path === "/health") {
      sendJSON(response, 200, { ok: true, service: "kungfu-follow-backend" });
      return;
    }

    if (request.method === "GET" && path === "/api") {
      sendJSON(response, 200, docs());
      return;
    }

    if (request.method === "GET" && path === "/api/routines") {
      const routines = await readJSON("routines.json", []);
      sendJSON(response, 200, { routines });
      return;
    }

    if (request.method === "GET" && path === "/api/checkins") {
      const userId = requestURL.searchParams.get("userId") ?? "demo-user";
      const [routines, checkIns] = await Promise.all([
        readJSON("routines.json", []),
        readJSON("checkins.json", [])
      ]);
      const result = checkIns
        .filter((item) => item.userId === userId)
        .sort((a, b) => b.practicedAt.localeCompare(a.practicedAt))
        .map((item) => publicCheckIn(item, routines));
      sendJSON(response, 200, { checkIns: result });
      return;
    }

    if (request.method === "POST" && path === "/api/checkins") {
      const payload = await readBody(request);
      const userId = String(payload.userId ?? "demo-user");
      const routineId = String(payload.routineId ?? "");

      if (userId.length < 2 || userId.length > 80) {
        badRequest(response, "userId must be 2-80 characters");
        return;
      }
      if (!/^[a-zA-Z0-9._-]+$/.test(userId)) {
        badRequest(response, "userId contains unsupported characters");
        return;
      }
      if (!/^[a-zA-Z0-9._-]+$/.test(routineId)) {
        badRequest(response, "routineId is required");
        return;
      }

      const [routines, checkIns] = await Promise.all([
        readJSON("routines.json", []),
        readJSON("checkins.json", [])
      ]);
      const routine = routines.find((item) => item.id === routineId);
      if (!routine) {
        sendJSON(response, 404, { error: "Routine not found" });
        return;
      }

      const today = new Date().toISOString().slice(0, 10);
      const existing = checkIns.find((item) => (
        item.userId === userId &&
        item.routineId === routineId &&
        item.practicedAt.slice(0, 10) === today
      ));

      if (existing) {
        sendJSON(response, 200, { checkIn: publicCheckIn(existing, routines), duplicated: true });
        return;
      }

      const checkIn = {
        id: randomUUID(),
        userId,
        routineId,
        routineTitle: routine.title,
        minutes: routine.duration,
        practicedAt: new Date().toISOString()
      };
      checkIns.unshift(checkIn);
      await writeJSON("checkins.json", checkIns);
      sendJSON(response, 201, { checkIn: publicCheckIn(checkIn, routines), duplicated: false });
      return;
    }

    if (request.method === "GET" && path === "/api/feed") {
      const [routines, checkIns] = await Promise.all([
        readJSON("routines.json", []),
        readJSON("checkins.json", [])
      ]);
      const feed = checkIns
        .slice()
        .sort((a, b) => b.practicedAt.localeCompare(a.practicedAt))
        .slice(0, 30)
        .map((item) => publicCheckIn(item, routines));
      sendJSON(response, 200, { feed });
      return;
    }

    sendJSON(response, 404, { error: "Not found" });
  } catch (error) {
    sendJSON(response, 500, { error: error.message });
  }
}

export function createAppServer() {
  return createServer(handler);
}

if (process.env.NODE_ENV !== "test") {
  createAppServer().listen(port, host, () => {
    console.log(`KungFu Follow backend listening on http://${host}:${port}`);
  });
}
