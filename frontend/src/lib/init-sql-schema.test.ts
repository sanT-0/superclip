// @vitest-environment node
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

// A fresh Docker volume builds its schema from init.sql, while the app talks to
// it through the Prisma client. When a migration adds a column and init.sql is
// not updated, every query touching that column fails at runtime (for example a
// 500 on sign-in when users.stripe_account_id was missing). Keep both in sync.
//
// init.sql lives at the repository root: two levels up when the tests run in
// the Docker image (compose mounts it at /app/init.sql), three when run from
// frontend/ on the host.
const readRepoFile = (name: string) => {
  for (const candidate of [`../../${name}`, `../../../${name}`]) {
    const path = fileURLToPath(new URL(candidate, import.meta.url));
    if (existsSync(path)) return readFileSync(path, "utf8");
  }
  throw new Error(`Could not find ${name} relative to ${import.meta.url}`);
};

type Model = { table: string; columns: string[] };

const prismaModels = (schema: string): Model[] => {
  const models: Model[] = [];
  for (const match of schema.matchAll(/^model\s+(\w+)\s*\{/gm)) {
    const start = match.index! + match[0].length;
    let depth = 1;
    let end = start;
    while (depth > 0 && end < schema.length) {
      if (schema[end] === "{") depth += 1;
      if (schema[end] === "}") depth -= 1;
      end += 1;
    }
    const body = schema.slice(start, end - 1);
    const table = body.match(/@@map\("([^"]+)"\)/)?.[1] ?? match[1];
    const columns: string[] = [];
    for (const rawLine of body.split("\n")) {
      const line = rawLine.trim();
      if (!line || line.startsWith("//") || line.startsWith("@@")) continue;
      const [field, type] = line.split(/\s+/);
      if (!field || !type) continue;
      // Relations and unsupported types have no column of their own.
      if (/^[A-Z]/.test(type) || type.includes("Unsupported")) continue;
      if (line.includes("@relation(")) continue;
      columns.push(line.match(/@map\("([^"]+)"\)/)?.[1] ?? field);
    }
    models.push({ table, columns });
  }
  return models;
};

describe("init.sql mirrors the Prisma schema", () => {
  const initSql = readRepoFile("init.sql");
  const initSqlLower = initSql.toLowerCase();
  const models = prismaModels(readRepoFile("prisma/schema.prisma"));

  const isDeclaredInInitSql = (table: string) =>
    new RegExp(`create\\s+table\\s+(if\\s+not\\s+exists\\s+)?"?${table}"?\\s*\\(`, "i").test(initSql);

  it("includes every column of every table it creates", () => {
    const missing: string[] = [];
    for (const { table, columns } of models) {
      if (!isDeclaredInInitSql(table)) continue;
      for (const column of columns) {
        if (!initSqlLower.includes(column.toLowerCase())) {
          missing.push(`${table}.${column}`);
        }
      }
    }
    expect(missing).toEqual([]);
  });
});
