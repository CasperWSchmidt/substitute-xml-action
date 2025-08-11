import * as core from '@actions/core';
import * as glob from '@actions/glob';
import * as fs from 'fs';
import { XMLParser, XMLBuilder } from 'fast-xml-parser';

async function run() {
  try {
    core.info('🔄 Starting XML substitution based on `key` and `name` attributes...');
    const filesInput = core.getInput('files', { required: true });
    const patterns = filesInput.split(/\r?\n/).map(p => p.trim()).filter(p => p);
    const resolvedFiles = new Set<string>();

    for (const pattern of patterns) {
      const globber = await glob.create(pattern);
      const files = await globber.glob();
      if (files.length === 0) {
        core.warning(`⚠️ No matches found for pattern: ${pattern}`);
      }
      for (const file of files) {
        core.info(`Found: ${file}`);
        resolvedFiles.add(file);
      }
    }

    if (resolvedFiles.size === 0) {
      core.setFailed('❌ No valid files found. Exiting.');
      return;
    }

    // Build case-insensitive environment variable map
    const envMap = new Map<string, string>();
    for (const [k, v] of Object.entries(process.env)) {
      envMap.set(k.toLowerCase(), v ?? '');
    }

    const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '' });
    const builder = new XMLBuilder({ ignoreAttributes: false, attributeNamePrefix: '', format: true });

    for (const file of resolvedFiles) {
      if (!fs.existsSync(file)) {
        core.warning(`⚠️ File not found: ${file}`);
        continue;
      }

      const content = fs.readFileSync(file, 'utf-8');
      let parsed;
      try {
        parsed = parser.parse(content);
      } catch {
        core.warning(`⚠️ Failed to parse XML in ${file}. Skipping.`);
        continue;
      }

      const appSettings = parsed.configuration?.appSettings?.add;
      if (!appSettings) {
        core.info(`ℹ️ No <add> nodes found in: ${file}`);
        continue;
      }

      let updated = false;
      const addNodes = Array.isArray(appSettings) ? appSettings : [appSettings];

      for (const node of addNodes) {
        // Match "key" attribute (case-insensitive)
        if (node.key && envMap.has(node.key.toLowerCase())) {
          const newVal = envMap.get(node.key.toLowerCase())!;
          if (node.value !== newVal) {
            core.info(`🔁 Updated key='${node.key}': '${node.value}' → '${newVal}'`);
            node.value = newVal;
            updated = true;
          }
        }
        // Match "name" attribute (case-insensitive)
        if (node.name && envMap.has(node.name.toLowerCase())) {
          const newVal = envMap.get(node.name.toLowerCase())!;
          if (node.connectionString !== newVal) {
            core.info(`🔁 Updated name='${node.name}': '${node.connectionString}' → '${newVal}'`);
            node.connectionString = newVal;
            updated = true;
          }
        }
      }

      if (updated) {
        const updatedXml = builder.build(parsed);
        fs.writeFileSync(file, updatedXml, 'utf-8');
        core.info(`💾 Saved: ${file}`);
      } else {
        core.info(`ℹ️ No substitutions needed in: ${file}`);
      }
    }

    core.info('✅ XML substitution complete.');
  } catch (error: any) {
    core.setFailed(error.message);
  }
}

run();
