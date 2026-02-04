#!/usr/bin/env node
/**
 * Prepares docs for Docusaurus by:
 * 1. Copying from ../docs/ to ./docs/
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

// Generate document ID from filename
function extractId(filename) {
  if (filename === 'README.md') {
    return 'index';
  }
  // Keep the number prefix to ensure unique IDs (e.g., "00-index" not "index")
  return filename.replace(/\.md$/, '');
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

// Process a single markdown file
function processFile(filename) {
  const sourcePath = path.join(SOURCE_DIR, filename);
  const targetPath = path.join(TARGET_DIR, filename);

  let content = fs.readFileSync(sourcePath, 'utf8');

  // Skip if already has frontmatter (shouldn't happen with clean source)
  if (hasFrontmatter(content)) {
    console.log(`  Skipping ${filename} (already has frontmatter)`);
    fs.writeFileSync(targetPath, content);
    return;
  }

  const id = extractId(filename);
  const title = extractTitle(content, filename);
  const position = extractPosition(filename);

  // Build frontmatter
  const frontmatter = [
    '---',
    `id: ${id}`,
    `title: "${title.replace(/"/g, '\\"')}"`,
    `sidebar_position: ${position}`,
  ];

  // Add slug for README to make it the index
  if (filename === 'README.md') {
    frontmatter.push('slug: /');
  }

  frontmatter.push('---', '');

  // Escape MDX special characters
  content = escapeMdx(content);

  // Combine frontmatter and content
  const output = frontmatter.join('\n') + content;

  fs.writeFileSync(targetPath, output);
  console.log(`  Processed ${filename} -> id: ${id}, position: ${position}`);
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

  // Get all markdown files
  const files = fs.readdirSync(SOURCE_DIR)
    .filter(f => f.endsWith('.md') && !f.startsWith('.'));

  console.log(`  Found ${files.length} markdown files`);

  // Process each file
  files.forEach(processFile);

  console.log('Done!');
}

main();
