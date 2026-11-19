/**
 * Markdown の文書に、見出しへのリンク付きの目次を作り直して入れる（記述方式：目次は手書きせず、自動生成する）。
 * 目次は、文書の `<!-- toc -->` と `<!-- /toc -->` のあいだに入れる。見出しの `##`〜`####` を拾う。
 * リンクは、GitHub と同じ規則（github-slugger）で作る。
 * 使い方（リポジトリの直下で）：
 *   deno run --allow-read --allow-write scripts/toc.ts docs/design/architecture/architecture-design.md
 * `--check` を付けると、書き換えずに、目次が古ければ終了コード 1 で終える。
 */
import GithubSlugger from "npm:github-slugger@2.0.0";

const START = "<!-- toc -->";
const END = "<!-- /toc -->";

/** 目次の行を作る。コードブロックの中の `#` は見出しにしない。 */
export function buildToc(markdown: string): string {
  const slugger = new GithubSlugger();
  const lines: string[] = [];
  let inCode = false;
  for (const line of markdown.split("\n")) {
    if (line.startsWith("```")) inCode = !inCode;
    if (inCode) continue;
    const m = line.match(/^(#{1,6}) (.+)$/);
    if (!m) continue;
    const level = m[1].length;
    const text = m[2].trim();
    // 同じ見出しの番号付け（-1 など）を GitHub と合わせるため、目次に入れない見出しも数える。
    const slug = slugger.slug(text.replace(/`/g, ""));
    if (level < 2 || level > 4) continue;
    lines.push(`${"  ".repeat(level - 2)}- [${text}](#${slug})`);
  }
  return lines.join("\n");
}

/** `<!-- toc -->` と `<!-- /toc -->` のあいだを、目次に置き換える。 */
export function replaceToc(markdown: string): string {
  const start = markdown.indexOf(START);
  const end = markdown.indexOf(END);
  if (start < 0 || end < start) throw new Error(`${START} と ${END} が見つからない`);
  return markdown.slice(0, start + START.length) + "\n\n" + buildToc(markdown) + "\n\n" +
    markdown.slice(end);
}

if (import.meta.main) {
  const check = Deno.args.includes("--check");
  const files = Deno.args.filter((a) => a !== "--check");
  let stale = false;
  for (const file of files) {
    const before = await Deno.readTextFile(file);
    const after = replaceToc(before);
    if (before === after) continue;
    if (check) {
      console.error(`${file}: 目次が古い`);
      stale = true;
    } else {
      await Deno.writeTextFile(file, after);
      console.log(`${file}: 目次を作り直した`);
    }
  }
  if (stale) Deno.exit(1);
}
