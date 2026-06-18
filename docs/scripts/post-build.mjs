#!/usr/bin/env node
// Post-build fixes for GitHub Pages subpath deployment.
//
// 1. Dirify: convert VitePress file-style output (foo.html) to directory-style
//    (foo/index.html) so GitHub Pages resolves BOTH /foo and /foo/. Without
//    this, /foo/ 404s because foo.html is a file, not a directory.
//
// 2. Sitemap base: insert the deployment base path into sitemap.xml URLs.
//    VitePress omits `base` from sitemap route paths (and ignores the path
//    portion of `sitemap.hostname`), so the generated URLs point at the origin
//    root instead of the subsite. We rewrite each <loc> to include the base.
//
// Idempotent. Kept at the dist root: index.html (site root), 404.html (GHP 404 page).
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

const DIST = ".vitepress/dist";
const HTML = ".html";
const KEEP_AT_ROOT = new Set(["index.html", "404.html"]);
// Subsite identity — must match config.ts base and the real deployment URL.
const ORIGIN = "https://www.fontist.org";
const BASE = "fontist"; // path segment under ORIGIN (no slashes)

let moved = 0;
let skipped = 0;

function dirify(dir) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      dirify(full);
      continue;
    }
    if (!entry.endsWith(HTML)) continue;
    if (entry === "index.html") continue; // already directory-style
    if (dir === DIST && KEEP_AT_ROOT.has(entry)) {
      skipped++; // root index.html / 404.html stay put
      continue;
    }
    const name = entry.slice(0, -HTML.length);
    const targetDir = join(dir, name);
    const targetIndex = join(targetDir, "index.html");
    if (existsSync(targetIndex)) {
      console.warn(`[post-build] skip ${full.replace(DIST + "/", "")}: target exists`);
      skipped++;
      continue;
    }
    mkdirSync(targetDir, { recursive: true });
    renameSync(full, targetIndex);
    moved++;
  }
}

function fixSitemapBase() {
  const sitemap = `${DIST}/sitemap.xml`;
  if (!existsSync(sitemap)) return false;
  let xml = readFileSync(sitemap, "utf8");
  // Insert BASE after the origin unless the path already starts with BASE
  // (VitePress emits the homepage route as "/<base>"; other routes omit it).
  const originPattern = new RegExp(
    `(<loc>${ORIGIN.replaceAll("/", "\\/")}\\/)(?!${BASE}(\\/|$))`,
    "g",
  );
  xml = xml.replace(originPattern, `$1${BASE}/`);
  writeFileSync(sitemap, xml);
  return true;
}

dirify(DIST);
const sitemapFixed = fixSitemapBase();
console.log(
  `[post-build] dirified ${moved} route(s), kept ${skipped} at root; sitemap ${sitemapFixed ? "rewritten with /" + BASE + "/" : "absent (skipped)"}`,
);
