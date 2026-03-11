import { defineConfig } from "vitepress";
import { fileURLToPath, URL } from "node:url";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  // Register custom components
  vite: {
    resolve: {
      alias: {
        "@components": fileURLToPath(new URL("../components", import.meta.url)),
      },
    },
  },
  lang: "en-US",

  // https://vitepress.dev/guide/routing#generating-clean-url
  cleanUrls: true,

  title: "Fontist",
  description:
    "Fontist brings cross-platform font management to the command line for Windows, Linux, and macOS. Free and open source.",

  lastUpdated: true,

  // Base path for deployment (e.g., /fontist/ for fontist.org/fontist/)
  base: process.env.BASE_PATH || "/fontist/",

  head: [
    [
      "link",
      { rel: "icon", type: "image/png", href: "/favicon-96x96.png", sizes: "96x96" },
    ],
    ["link", { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" }],
    ["link", { rel: "shortcut icon", href: "/favicon.ico" }],
    [
      "link",
      { rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png" },
    ],
    ["link", { rel: "manifest", href: "/site.webmanifest" }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:title", content: "Fontist" }],
    [
      "meta",
      {
        property: "og:description",
        content:
          "Fontist brings cross-platform font management to the command line for Windows, Linux, and macOS.",
      },
    ],
    ["meta", { property: "og:image", content: "/logo-full.svg" }],
    ["meta", { name: "twitter:card", content: "summary_large_image" }],
  ],

  // https://vitepress.dev/reference/default-theme-config
  themeConfig: {
    logo: "/logo-full.svg",
    siteTitle: false,

    // Local search with MiniSearch
    search: {
      provider: "local",
      options: {
        detailedView: true,
        miniSearch: {
          searchOptions: {
            fuzzy: 0.2,
            prefix: true,
            boost: { title: 4, text: 2, titles: 1 },
          },
        },
      },
    },

    nav: [
      { text: "← Fontist.org", link: "https://www.fontist.org" },
      { text: "Guide", link: "/guide/" },
      { text: "CLI", link: "/cli/" },
      { text: "API", link: "/api/" },
      { text: "Formulas", link: "https://www.fontist.org/formulas/", target: "_self" },
      { text: "Fontisan", link: "https://www.fontist.org/fontisan/", target: "_self" },
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Getting Started",
          items: [
            { text: "Introduction", link: "/guide/" },
            { text: "Installation", link: "/guide/installation" },
            { text: "Quick Start", link: "/guide/quick-start" },
          ],
        },
        {
          text: "Concepts",
          items: [
            { text: "Overview", link: "/guide/concepts/" },
            { text: "Fonts & Styles", link: "/guide/concepts/fonts" },
            { text: "Variable Fonts", link: "/guide/concepts/variable-fonts" },
            { text: "Formats & Containers", link: "/guide/concepts/formats" },
            { text: "Licenses", link: "/guide/concepts/licenses" },
            { text: "Requirements", link: "/guide/concepts/requirements" },
          ],
        },
        {
          text: "Learn More",
          collapsed: true,
          items: [
            { text: "How Fontist Works", link: "/guide/how-it-works" },
            { text: "Why Fontist?", link: "/guide/why" },
            { text: "Manifests", link: "/guide/manifests" },
            { text: "Formulas", link: "/guide/formulas" },
          ],
        },
        {
          text: "Guides",
          collapsed: true,
          items: [
            { text: "CI/CD Integration", link: "/guide/ci" },
            { text: "Fontconfig", link: "/guide/fontconfig" },
            { text: "Proxy Setup", link: "/guide/proxy" },
            {
              text: "Create a Formula",
              link: "https://www.fontist.org/formulas/guide/create-formula",
              target: "_self",
            },
          ],
        },
        {
          text: "Platforms",
          collapsed: true,
          items: [
            { text: "Overview", link: "/guide/platforms/" },
            { text: "macOS", link: "/guide/platforms/macos" },
            { text: "Windows", link: "/guide/platforms/windows" },
          ],
        },
        {
          text: "Maintainer Docs",
          collapsed: true,
          items: [
            { text: "Overview", link: "/guide/maintainer/" },
            { text: "Importing Fonts", link: "/guide/maintainer/import" },
          ],
        },
      ],
      "/cli/": [
        {
          text: "CLI Reference",
          items: [
            { text: "Overview", link: "/cli/" },
          ],
        },
        {
          text: "Core Commands",
          items: [
            { text: "install", link: "/cli/install" },
            { text: "uninstall", link: "/cli/uninstall" },
            { text: "list", link: "/cli/list" },
            { text: "status", link: "/cli/status" },
            { text: "update", link: "/cli/update" },
            { text: "version", link: "/cli/version" },
          ],
        },
        {
          text: "Subcommands",
          collapsed: true,
          items: [
            { text: "manifest", link: "/cli/manifest" },
            { text: "cache", link: "/cli/cache" },
            { text: "config", link: "/cli/config" },
            { text: "repo", link: "/cli/repo" },
            { text: "fontconfig", link: "/cli/fontconfig" },
            { text: "import", link: "/cli/import" },
            { text: "index", link: "/cli/index-cmd" },
            { text: "create-formula", link: "/cli/create-formula" },
          ],
        },
        {
          text: "Reference",
          collapsed: true,
          items: [
            { text: "Exit Codes", link: "/cli/exit-codes" },
          ],
        },
      ],
      "/api/": [
        {
          text: "API Reference",
          items: [
            { text: "Overview", link: "/api/" },
          ],
        },
        {
          text: "Classes",
          items: [
            { text: "Fontist::Font", link: "/api/font" },
            { text: "Fontist::Formula", link: "/api/formula" },
            { text: "Fontist::Manifest", link: "/api/manifest" },
            { text: "Fontist::Fontconfig", link: "/api/fontconfig" },
          ],
        },
        {
          text: "Errors",
          collapsed: true,
          items: [
            { text: "Fontist::Errors", link: "/api/errors" },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/fontist/fontist" },
    ],

    footer: {
      message: `Fontist is <a href="https://open.ribose.com/">riboseopen</a>`,
      copyright: `Copyright &copy; 2026 Ribose Group Inc. All rights reserved.`,
    },
  },
});
