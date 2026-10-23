// API 문서(docs/api/*.md)와 코드(Spring 컨트롤러 매핑)의 엔드포인트 목록을 기계적으로 비교
// 메서드·경로 일치만 확인. 파라미터·필드·에러 코드 대조는 verifier(mode=api)가 담당
//
// 사용법:
//   node scripts/check-api.mjs          전체 비교 (코드에만 있는 엔드포인트도 문제로 집계)
//   node scripts/check-api.mjs F-01     해당 feature 문서 엔드포인트가 코드에 있는지만 집계
//
// 경로 접두어(context-path 등)는 docs/project.md의 "- API 경로 접두어:" 값을 코드 경로 앞에 붙임
// 상수·프로퍼티로 만든 경로는 해석하지 못해 "해석 불가"로 따로 보고. 문제가 하나라도 있으면 exit 1
import { execSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const root = (() => {
  try {
    return execSync("git rev-parse --show-toplevel", { encoding: "utf8" }).trim();
  } catch {
    return process.cwd();
  }
})();
const feature = process.argv[2];
const METHODS = ["GET", "POST", "PUT", "PATCH", "DELETE"];

const normalize = (path) =>
  `/${path}`
    .replace(/\/+/g, "/")
    .replace(/\{[^}]*\}/g, "{}")
    .replace(/(.)\/$/, "$1");

const projectPrefix = () => {
  const file = join(root, "docs/project.md");
  if (!existsSync(file)) return "";
  const m = readFileSync(file, "utf8").match(/^- API 경로 접두어:[ \t]*(\/\S*)?/m);
  return m?.[1] ?? "";
};

const docEndpoints = () => {
  const dir = join(root, "docs/api");
  if (!existsSync(dir)) return [];
  const result = [];
  for (const name of readdirSync(dir)) {
    if (!name.endsWith(".md") || name === "_template.md") continue;
    const file = join("docs/api", name);
    let current = null;
    readFileSync(join(root, file), "utf8")
      .split("\n")
      .forEach((line, i) => {
        const head = line.match(/^#{2,4}\s+(API-\d+)\s+([A-Z]+)\s+(\S+)/);
        if (head) {
          current = { id: head[1], method: head[2], path: head[3], key: `${head[2]} ${normalize(head[3])}`, file: `${file}:${i + 1}`, feature: null, status: null };
          result.push(current);
          return;
        }
        if (/^#{1,4}\s/.test(line)) current = null;
        if (!current) return;
        const f = line.match(/^- feature:\s*(F-\d+)/);
        if (f) current.feature = f[1];
        const s = line.match(/^- API 상태:\s*(\S+)/);
        if (s) current.status = s[1];
      });
  }
  return result;
};

const sourceFiles = (dir, out = []) => {
  for (const name of readdirSync(dir)) {
    if (name.startsWith(".") || ["build", "target", "node_modules", "out"].includes(name)) continue;
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) sourceFiles(full, out);
    else if (/\.(java|kt)$/.test(name) && /[\\/]src[\\/]main[\\/]/.test(full)) out.push(full);
  }
  return out;
};

const literals = (args) => [...(args ?? "").matchAll(/"([^"]*)"/g)].map((m) => m[1]);

// 경로 인자가 문자열 리터럴이 아니면(상수·프로퍼티) 해석 불가로 표시
const mappingPaths = (args) => {
  const raw = (args ?? "").replace(/\b(method|produces|consumes|params|headers)\s*=\s*(\{[^}]*\}|[^,)]*)/g, "");
  const paths = literals(raw);
  if (paths.length) return { paths, unresolved: false };
  return { paths: [""], unresolved: /[A-Za-z_$][\w.$]*/.test(raw.replace(/\b(value|path)\s*=/g, "")) };
};

const codeEndpoints = (prefix) => {
  const result = [];
  const unresolved = [];
  for (const full of sourceFiles(root)) {
    const text = readFileSync(full, "utf8");
    if (!/@(Rest)?Controller\b/.test(text)) continue;
    const file = relative(root, full);
    const classMatch = text.match(/\b(class|object)\s+\w+/);
    const classIdx = classMatch?.index ?? 0;
    const lineOf = (idx) => text.slice(0, idx).split("\n").length;
    let classPaths = [""];
    const re = /@(Get|Post|Put|Patch|Delete|Request)Mapping\b\s*(?:\(([^)]*)\))?/g;
    for (const m of text.matchAll(re)) {
      const { paths, unresolved: bad } = mappingPaths(m[2]);
      if (m.index < classIdx) {
        if (m[1] === "Request") {
          classPaths = paths;
          if (bad) unresolved.push(`${file}:${lineOf(m.index)} 클래스 경로`);
        }
        continue;
      }
      const methods = m[1] === "Request" ? [...(m[2] ?? "").matchAll(/RequestMethod\.(\w+)/g)].map((x) => x[1]) : [m[1].toUpperCase()];
      if (bad) {
        unresolved.push(`${file}:${lineOf(m.index)} ${m[0].replace(/\s+/g, " ")}`);
        continue;
      }
      for (const method of methods.length ? methods : ["ANY"]) {
        for (const c of classPaths) {
          for (const p of paths) {
            const path = normalize(`${prefix}/${c}/${p}`);
            result.push({ method, path, key: `${method} ${path}`, file: `${file}:${lineOf(m.index)}` });
          }
        }
      }
    }
  }
  return { result, unresolved };
};

const docs = docEndpoints();
const prefix = projectPrefix();
const { result: code, unresolved } = codeEndpoints(prefix);
const codeKeys = new Set(code.map((e) => e.key));
const anyPaths = new Set(code.filter((e) => e.method === "ANY").map((e) => e.path));
const inCode = (d) => codeKeys.has(d.key) || anyPaths.has(normalize(d.path));
const problems = [];
const report = (kind, msg) => problems.push(`[${kind}] ${msg}`);

const ids = new Map();
for (const d of docs) {
  if (ids.has(d.id)) report("ID 중복", `${d.id}: ${ids.get(d.id)}, ${d.file}`);
  ids.set(d.id, d.file);
  if (!METHODS.includes(d.method)) report("메서드 오류", `${d.id} ${d.method}: ${d.file}`);
  if (!d.feature) report("feature 없음", `${d.id}: ${d.file}`);
}

const targets = docs.filter((d) => !feature || d.feature === feature);
if (feature && !targets.length) report("문서 없음", `${feature}에 해당하는 엔드포인트가 docs/api/에 없음`);
for (const d of targets) {
  if (d.status === "폐기") {
    if (inCode(d)) report("폐기 미반영", `${d.id} ${d.method} ${d.path}: 문서는 폐기인데 코드에 남아 있음`);
  } else if (!inCode(d)) {
    report("미구현", `${d.id} ${d.method} ${d.path} (${d.file}): 코드에 매핑 없음`);
  }
}

if (!feature) {
  // 폐기 문서와 같은 매핑은 위에서 "폐기 미반영"으로 이미 보고하므로 문서 누락에서 제외
  const docKeys = new Set(docs.map((d) => d.key));
  for (const c of code) {
    if (c.method === "ANY") {
      if (![...docKeys].some((k) => k.endsWith(` ${c.path}`))) report("문서 누락", `ANY ${c.path} (${c.file}): 메서드 미지정 매핑, 문서에 없음`);
    } else if (!docKeys.has(c.key)) {
      report("문서 누락", `${c.key} (${c.file}): 코드에만 있음`);
    }
  }
}

for (const u of unresolved) console.log(`[해석 불가] ${u} - 리터럴이 아닌 경로라 직접 확인 필요`);
for (const p of problems) console.log(p);
console.log(`문서 엔드포인트 ${targets.length}건${feature ? `(${feature})` : ""}, 코드 매핑 ${code.length}건, 경로 접두어 '${prefix || "없음"}'`);
if (problems.length) {
  console.log(`문제 ${problems.length}건`);
  process.exit(1);
}
console.log(unresolved.length ? "문제 없음 (해석 불가 항목은 직접 확인)" : "문제 없음");
