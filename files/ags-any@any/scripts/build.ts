import { build } from "esbuild";
import { sassPlugin } from "esbuild-sass-plugin";

await build({
   entryPoints: ["src/main.tsx"],
   outdir: "build",

   bundle: true,
   platform: "neutral",
   target: "ES2022",
   format: "esm",
   sourcemap: "inline",

   external: [
      "gi://*",
      "file://*",
      "resource://*",
      "system",
      "console",
      "cairo",
      "gettext",
   ],

   plugins: [sassPlugin({ type: "css-text" })],
});
