import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// @ts-expect-error process is a nodejs global
const host = process.env.TAURI_DEV_HOST;

export default defineConfig(async () => ({
  plugins: [react(), tailwindcss()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes("node_modules")) return
          if (/[\\/]node_modules[\\/](react|react-dom|scheduler)[\\/]/.test(id))
            return "react-vendor"
          if (id.includes("framer-motion")) return "motion"
          if (id.includes("i18next")) return "i18n"
          if (
            /react-markdown|remark|micromark|mdast|hast|unist|vfile|unified|property-information|character-entities|space-separated-tokens|comma-separated-tokens|decode-named-character-reference|trough|bail|zwitch|html-void-elements|web-namespaces|ccount|markdown-table|longest-streak|devlop/.test(
              id,
            )
          )
            return "markdown"
          if (id.includes("@dnd-kit")) return "dnd"
          if (id.includes("@fortawesome") || id.includes("country-flag-icons"))
            return "icons"
          return "vendor"
        },
      },
    },
  },

  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
    host: host || false,
    hmr: host
      ? {
          protocol: "ws",
          host,
          port: 1421,
        }
      : undefined,
    watch: {
      ignored: ["**/src-tauri/**"],
    },
  },
}));
