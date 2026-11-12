const fs = require('fs');
const path = require('path');
const { generateFonts } = require('fantasticon');

const SYSTEM_ICONS_PATH = '/usr/share/icons/Adwaita/symbolic';
const STAGING_PATH = path.join(__dirname, 'staging_svgs');
const OUTPUT_FONTS_PATH = path.join(__dirname, '..', 'assets', 'fonts');
const OUTPUT_DART_PATH = path.join(__dirname, '..', 'lib', 'libadwaitter_icons.dart');

function sanitizeName(fileName) {
  return fileName
    .replace(/\.svg$/, '')
    .replace(/[^a-zA-Z0-9_]/g, '_')
    .toLowerCase();
}

async function run() {
  console.log('1. Escaneando iconos simbólicos de Adwaita...');
  if (!fs.existsSync(SYSTEM_ICONS_PATH)) {
    console.error(`Error: No se encontró la ruta de iconos del sistema: ${SYSTEM_ICONS_PATH}`);
    process.exit(1);
  }

  if (fs.existsSync(STAGING_PATH)) {
    fs.rmSync(STAGING_PATH, { recursive: true, force: true });
  }
  fs.mkdirSync(STAGING_PATH, { recursive: true });

  const categories = fs.readdirSync(SYSTEM_ICONS_PATH);
  let totalCopied = 0;
  const processedNames = new Set();

  for (const cat of categories) {
    const catPath = path.join(SYSTEM_ICONS_PATH, cat);
    if (!fs.statSync(catPath).isDirectory()) continue;

    const files = fs.readdirSync(catPath).filter(f => f.endsWith('.svg'));
    for (const file of files) {
      const cleanName = sanitizeName(file);
      if (processedNames.has(cleanName)) continue; // Evitar colisiones entre categorías
      processedNames.add(cleanName);

      const src = path.join(catPath, file);
      const dst = path.join(STAGING_PATH, `${cleanName}.svg`);
      fs.copyFileSync(src, dst);
      totalCopied++;
    }
  }

  console.log(`2. Se prepararon ${totalCopied} iconos únicos en la carpeta de staging.`);

  console.log('3. Generando fuente TrueType (AdwaitaIcons.ttf)...');
  fs.mkdirSync(OUTPUT_FONTS_PATH, { recursive: true });

  const results = await generateFonts({
    inputDir: STAGING_PATH,
    outputDir: OUTPUT_FONTS_PATH,
    name: 'AdwaitaIcons',
    fontTypes: ['ttf'],
    assetTypes: ['json'],
    codepoints: {},
    prefix: '',
    normalize: true,
  });

  console.log('4. Generando clase Dart de mapeo (libadwaitter_icons.dart)...');
  const jsonPath = path.join(OUTPUT_FONTS_PATH, 'AdwaitaIcons.json');
  const glyphMap = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

  let dartCode = `// GENERADO AUTOMÁTICAMENTE - NO EDITAR MANUALMENTE
// Basado en adwaita-icon-theme oficial de GNOME en GitLab:
// https://gitlab.gnome.org/GNOME/adwaita-icon-theme

import 'package:flutter/widgets.dart';

/// Conjunto oficial de iconos simbólicos de Adwaita para Flutter.
abstract final class AdwIcons {
  static const String _fontFamily = 'AdwaitaIcons';
  static const String _fontPackage = 'libadwaitter_icons';

`;

  const sortedKeys = Object.keys(glyphMap).sort();
  for (const key of sortedKeys) {
    const codePoint = glyphMap[key];
    const hex = Number(codePoint).toString(16).padStart(4, '0');
    // Si el nombre empieza con número, agregar un prefijo
    const identifier = /^[0-9]/.test(key) ? `icon_${key}` : key;
    dartCode += `  /// Icono simbólico \`${key}\`.\n`;
    dartCode += `  static const IconData ${identifier} = IconData(0x${hex}, fontFamily: _fontFamily, fontPackage: _fontPackage);\n\n`;
  }

  dartCode += `}\n`;

  fs.mkdirSync(path.dirname(OUTPUT_DART_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_DART_PATH, dartCode, 'utf8');

  // Limpieza de JSON temporal
  if (fs.existsSync(jsonPath)) {
    fs.unlinkSync(jsonPath);
  }

  console.log(`✅ ¡Generación completada con éxito! ${sortedKeys.length} iconos disponibles en AdwIcons.`);
}

run().catch(err => {
  console.error('Error durante la generación:', err);
  process.exit(1);
});

