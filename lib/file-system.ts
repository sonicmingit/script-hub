import fs from 'fs';
import path from 'path';

const DATA_DIR = path.join(process.cwd(), 'data', 'scripts');

export interface ScriptFile {
  name: string;
  path: string; // Relative path from DATA_DIR, e.g., "deploy/start.sh"
  category: string;
  extension: string;
  size: number;
  updatedAt: Date;
  description?: string;
}

export interface Category {
  name: string;
  scripts: ScriptFile[];
}

// Ensure data dir exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

export function getAllScripts(): Category[] {
  const categories: Category[] = [];

  // Get all items in root data dir
  const items = fs.readdirSync(DATA_DIR, { withFileTypes: true });

  // 1. Root level scripts (Uncategorized)
  const rootScripts: ScriptFile[] = [];

  items.forEach(item => {
    if (item.isFile() && !item.name.startsWith('.')) {
      rootScripts.push(getFileDetails(item.name, 'Uncategorized'));
    } else if (item.isDirectory() && !item.name.startsWith('.')) {
      // 2. Categories (Folders)
      const categoryName = item.name;
      const categoryPath = path.join(DATA_DIR, categoryName);
      const categoryScripts: ScriptFile[] = [];

      const subItems = fs.readdirSync(categoryPath, { withFileTypes: true });
      subItems.forEach(subItem => {
        if (subItem.isFile() && !subItem.name.startsWith('.')) {
          categoryScripts.push(getFileDetails(path.join(categoryName, subItem.name), categoryName));
        }
      });

      if (categoryScripts.length > 0) {
        categories.push({
          name: categoryName,
          scripts: categoryScripts
        });
      }
    }
  });

  if (rootScripts.length > 0) {
    categories.push({
      name: 'Uncategorized',
      scripts: rootScripts
    });
  }

  return categories;
}

function getFileDetails(relativePath: string, category: string): ScriptFile {
  const fullPath = path.join(DATA_DIR, relativePath);
  const stat = fs.statSync(fullPath);

  return {
    name: path.basename(relativePath),
    path: relativePath.replace(/\\/g, '/'), // Normalize for web
    category,
    extension: path.extname(relativePath).toLowerCase(),
    size: stat.size,
    updatedAt: stat.mtime,
    description: extractDescription(fullPath)
  };
}

function extractDescription(filePath: string): string | undefined {
  try {
    // Read first 1024 bytes to find description in header
    const buffer = Buffer.alloc(1024);
    const fd = fs.openSync(filePath, 'r');
    const bytesRead = fs.readSync(fd, buffer, 0, 1024, 0);
    fs.closeSync(fd);

    const content = buffer.toString('utf-8', 0, bytesRead);
    const lines = content.split('\n');

    const descriptionLines: string[] = [];
    let inCommentBlock = false;

    for (const line of lines) {
      const trimmed = line.trim();

      // Skip shebang
      if (trimmed.startsWith('#!')) continue;

      // Start capturing if line starts with comment char
      if (trimmed.startsWith('#') || trimmed.startsWith('//')) {
        inCommentBlock = true;
        // Clean comment markers
        const cleanLine = trimmed.replace(/^[#\/]+\s*/, '').trim();
        // Ignore separator lines (e.g. ==== or ----)
        if (!/^[=\-]+$/.test(cleanLine)) {
          descriptionLines.push(cleanLine);
        }
      } else {
        // Stop if we hit a non-comment line, unless it's just an empty line between comments?
        // Let's assume description block is contiguous at the top.
        // If we extracted something and hit non-comment, we are done.
        if (inCommentBlock && trimmed !== '') {
          break;
        }
        // If we haven't started yet, keep looking.
        // But usually header comments are at the very top.
      }
    }

    // Join first few lines
    if (descriptionLines.length > 0) {
      // Return max 5 lines joined
      return descriptionLines.slice(0, 5).join('\n');
    }

  } catch (e) {
    // Ignore errors
  }
  return undefined;
}

export function getScriptContent(relativePath: string): string | null {
  const fullPath = path.join(DATA_DIR, relativePath);

  // Security check to prevent directory traversal
  if (!fullPath.startsWith(DATA_DIR)) {
    return null;
  }

  if (fs.existsSync(fullPath)) {
    return fs.readFileSync(fullPath, 'utf-8');
  }
  return null;
}

export function saveScript(relativePath: string, content: string): boolean {
  const fullPath = path.join(DATA_DIR, relativePath);

  // Security check
  if (!fullPath.startsWith(DATA_DIR)) {
    return false;
  }

  try {
    const dir = path.dirname(fullPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(fullPath, content, 'utf-8');
    return true;
  } catch (e) {
    console.error("Save failed:", e);
    return false;
  }
}

export function deleteScript(relativePath: string): boolean {
  const fullPath = path.join(DATA_DIR, relativePath);
  // Security check
  if (!fullPath.startsWith(DATA_DIR)) {
    return false;
  }

  try {
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
      // Remove directory if empty? Maybe later.
      return true;
    }
  } catch (e) {
    console.error("Delete failed:", e);
  }
  return false;
}
