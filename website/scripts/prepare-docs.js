#!/usr/bin/env node
/**
 * Prepares docs for Docusaurus by:
 * 1. Copying from ../docs/ to ./docs/ (recursively, preserving subdirectories)
 * 2. Adding frontmatter (id, title, sidebar_position)
 * 3. Escaping MDX special characters
 */

const fs = require('fs');
const path = require('path');

const SOURCE_DIR = path.join(__dirname, '../../docs');
const TARGET_DIR = path.join(__dirname, '../docs');

// Extract title from first H1 heading or filename
function extractTitle(content, filename) {
  const h1Match = content.match(/^#\s+(.+)$/m);
  if (h1Match) {
    return h1Match[1].trim();
  }
  // Fallback: convert filename to title
  return filename
    .replace(/^\d+-/, '')
    .replace(/\.md$/, '')
    .replace(/-/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase());
}

// Extract sidebar position from filename prefix (e.g., "00-" -> 0)
function extractPosition(filename) {
  const match = filename.match(/^(\d+)-/);
  if (match) {
    return parseInt(match[1], 10);
  }
  if (filename === 'README.md') {
    return 0;
  }
  return 999;
}

// Generate document ID from filename and relative directory.
// IDs must be unique across the docs tree but cannot contain slashes
// (Docusaurus rejects them in frontmatter ids), so we join the relative
// directory and leaf with hyphens. The route URL is derived from the
// file's path on disk and is unaffected by this id.
function extractId(filename, relativeDir) {
  const base = filename === 'README.md'
    ? 'index'
    : filename.replace(/\.md$/, '');
  if (!relativeDir) return base;
  return `${relativeDir.replace(/[\\/]+/g, '-')}-${base}`;
}

// Escape MDX special characters in content (but not in code blocks)
function escapeMdx(content) {
  const codeBlocks = [];

  // Temporarily replace code blocks
  let processed = content.replace(/```[\s\S]*?```/g, (match) => {
    codeBlocks.push(match);
    return `__CODE_BLOCK_${codeBlocks.length - 1}__`;
  });

  // Also protect inline code
  const inlineCode = [];
  processed = processed.replace(/`[^`]+`/g, (match) => {
    inlineCode.push(match);
    return `__INLINE_CODE_${inlineCode.length - 1}__`;
  });

  // Escape curly braces (MDX interprets as JSX expressions)
  processed = processed.replace(/\{([^}]+)\}/g, '\\{$1\\}');

  // Escape < that aren't part of HTML tags or code (MDX interprets as JSX)
  // Only escape standalone < like "<50" or "<->"
  processed = processed.replace(/<(?![a-zA-Z\/!])/g, '\\<');

  // Restore inline code
  inlineCode.forEach((code, i) => {
    processed = processed.replace(`__INLINE_CODE_${i}__`, code);
  });

  // Restore code blocks
  codeBlocks.forEach((block, i) => {
    processed = processed.replace(`__CODE_BLOCK_${i}__`, block);
  });

  return processed;
}

// Check if file already has frontmatter
function hasFrontmatter(content) {
  return content.startsWith('---\n');
}

// Process a single markdown file. `relativeDir` is the path of the file's
// containing directory relative to SOURCE_DIR (empty string for top-level).
function processFile(filename, relativeDir) {
  const sourcePath = path.join(SOURCE_DIR, relativeDir, filename);
  const targetDir = path.join(TARGET_DIR, relativeDir);
  const targetPath = path.join(targetDir, filename);

  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  let content = fs.readFileSync(sourcePath, 'utf8');

  // Skip if already has frontmatter (shouldn't happen with clean source)
  if (hasFrontmatter(content)) {
    console.log(`  Skipping ${path.join(relativeDir, filename)} (already has frontmatter)`);
    fs.writeFileSync(targetPath, content);
    return;
  }

  const title = extractTitle(content, filename);
  const position = extractPosition(filename);

  // Build frontmatter. We only set an explicit `id` for top-level docs,
  // where it preserves backward-compatible URLs and matches the existing
  // sidebar ordering. For nested docs we omit `id` entirely so that
  // Docusaurus derives both the id and the route from the file path,
  // giving stable URLs like `/docs/adr/0001-aws-identity-center` without
  // any need to encode the directory in the id (which Docusaurus rejects
  // when it contains slashes).
  const frontmatter = ['---'];
  if (relativeDir === '') {
    const id = extractId(filename, relativeDir);
    frontmatter.push(`id: ${id}`);
  }
  frontmatter.push(
    `title: "${title.replace(/"/g, '\\"')}"`,
    `sidebar_position: ${position}`,
  );

  // Add slug for the top-level README to make it the docs index. Nested
  // README/index files become the index of their containing folder
  // automatically.
  if (filename === 'README.md' && relativeDir === '') {
    frontmatter.push('slug: /');
  }

  frontmatter.push('---', '');

  // Escape MDX special characters
  content = escapeMdx(content);

  // Combine frontmatter and content
  const output = frontmatter.join('\n') + content;

  fs.writeFileSync(targetPath, output);
  console.log(`  Processed ${path.join(relativeDir, filename)} -> position: ${position}`);
}

// Walk the source tree, processing every markdown file we find. Skips
// dotfiles and dot-directories so that `docs/.meta/` and similar provenance
// folders are left alone.
function walk(relativeDir) {
  const dir = path.join(SOURCE_DIR, relativeDir);
  const entries = fs.readdirSync(dir, { withFileTypes: true })
    .filter(e => !e.name.startsWith('.'));

  for (const entry of entries) {
    if (entry.isDirectory()) {
      walk(path.join(relativeDir, entry.name));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      processFile(entry.name, relativeDir);
    }
  }
}

// Main
function main() {
  console.log('Preparing docs for Docusaurus...');
  console.log(`  Source: ${SOURCE_DIR}`);
  console.log(`  Target: ${TARGET_DIR}`);

  // Clean target directory
  if (fs.existsSync(TARGET_DIR)) {
    fs.rmSync(TARGET_DIR, { recursive: true });
  }
  fs.mkdirSync(TARGET_DIR, { recursive: true });

  walk('');

  console.log('Done!');
}

main();
