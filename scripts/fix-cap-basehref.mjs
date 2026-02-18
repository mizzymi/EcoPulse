import fs from "node:fs";
import path from "node:path";

const dist = path.resolve("dist/ecopulse/browser");
const locales = ["en-US", "es-ES", "ca-ES", "gl-ES"];

const redirectIndex = `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script>
      (function () {
        const supported = ['en-US', 'es-ES', 'ca-ES', 'gl-ES'];

        const saved = localStorage.getItem('lang');
        const deviceLang = navigator.language || '';
        const langRaw = (saved || deviceLang).toLowerCase();

        const match =
          supported.find((l) => l.toLowerCase().startsWith(langRaw.split('-')[0])) || 'es-ES';

        const path = window.location.pathname || '/';

        // Si ya estamos dentro de /{locale}/ o /{locale}/index.html, NO redirigir
        const re = new RegExp(\`^/(\${supported.join('|')})(/index\\\\.html)?(/|$)\`, 'i');
        if (re.test(path)) return;

        // Redirige al entry real del build localizado
        const target = \`/\${match}/index.html\${window.location.search}\${window.location.hash}\`;
        window.location.replace(target);
      })();
    </script>
  </head>
  <body></body>
</html>
`;

fs.mkdirSync(dist, { recursive: true });
fs.writeFileSync(path.join(dist, "index.html"), redirectIndex, "utf8");

function patchBaseHref(file) {
  if (!fs.existsSync(file)) return false;

  let html = fs.readFileSync(file, "utf8");
  const before = html;

  // ✅ reemplaza <base href="..."> y <base href="..." />
  html = html.replace(/<base\s+href="[^"]*"\s*\/?>/i, '<base href="./">');

  if (html !== before) {
    fs.writeFileSync(file, html, "utf8");
    console.log("fixed", file);
    return true;
  }

  console.log("ok", file);
  return false;
}

for (const loc of locales) {
  patchBaseHref(path.join(dist, loc, "index.html"));
}

