import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import assert from "node:assert/strict";

async function withServer(callback) {
  process.env.NODE_ENV = "test";
  process.env.DATA_DIR = await mkdtemp(join(tmpdir(), "kungfu-follow-"));
  const { createAppServer } = await import(`../src/server.js?test=${Date.now()}`);
  const server = createAppServer();

  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  const baseURL = `http://127.0.0.1:${port}`;

  try {
    await callback(baseURL);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await rm(process.env.DATA_DIR, { recursive: true, force: true });
  }
}

test("serves routines and records a check-in", async () => {
  await withServer(async (baseURL) => {
    const routinesResponse = await fetch(`${baseURL}/api/routines`);
    assert.equal(routinesResponse.status, 200);
    const routinesBody = await routinesResponse.json();
    assert.equal(routinesBody.routines.length, 3);

    const checkInResponse = await fetch(`${baseURL}/api/checkins`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ userId: "demo-user", routineId: "shaolin-foundation" })
    });
    assert.equal(checkInResponse.status, 201);
    const checkInBody = await checkInResponse.json();
    assert.equal(checkInBody.checkIn.routineTitle, "少林五步拳入门");

    const historyResponse = await fetch(`${baseURL}/api/checkins?userId=demo-user`);
    const historyBody = await historyResponse.json();
    assert.equal(historyBody.checkIns.length, 1);
  });
});

test("deduplicates same routine check-in per day", async () => {
  await withServer(async (baseURL) => {
    for (let index = 0; index < 2; index += 1) {
      await fetch(`${baseURL}/api/checkins`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ userId: "demo-user", routineId: "tai-chi-flow" })
      });
    }

    const historyResponse = await fetch(`${baseURL}/api/checkins?userId=demo-user`);
    const historyBody = await historyResponse.json();
    assert.equal(historyBody.checkIns.length, 1);
  });
});

test("rejects invalid check-in payloads", async () => {
  await withServer(async (baseURL) => {
    const response = await fetch(`${baseURL}/api/checkins`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ userId: "bad user", routineId: "shaolin-foundation" })
    });

    assert.equal(response.status, 400);
    const body = await response.json();
    assert.match(body.error, /userId/);
  });
});
