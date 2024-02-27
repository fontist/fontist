import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  // https://vitepress.dev/guide/routing#generating-clean-url
  cleanUrls: true,

  title: "Fontist",
  description:
    "Fontist brings cross-platform font management to the command line for Windows, Linux, and macOS. Free and open source.",

  // https://github.com/vuejs/vitepress/issues/3508
  base: process.env.BASE_PATH,

  // https://vitepress.dev/reference/default-theme-config
  themeConfig: {
    logo: "/logo.png",

    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/" },
      { text: "Reference", link: "/reference/" },
      {
        text: "Formulas",
        link: "https://fontist.org/formulas/",
        target: "_self",
      },
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Guide",
          items: [
            { text: "Why Fontist?", link: "/guide/why" },
            { text: "Getting started", link: "/guide/" },
            { text: "Using Fontist in CI", link: "/guide/ci" },
            { text: "Fontist with Fontconfig", link: "/guide/fontconfig" },
            { text: "Using Fontist with a proxy", link: "/guide/proxy" },
            {
              text: "Create a new Fontist Formula",
              link: "https://fontist.org/formulas/guide/create-formula",
              target: "_self",
            },
          ],
        },
        {
          text: "API",
          items: [
            { text: "Fontist Ruby library", link: "/guide/api-ruby" },
            {
              text: "Ruby API reference",
              link: "https://fontist.org/fontist/reference/api-ruby/",
              target: "_self",
            },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            { text: "Fontist CLI reference", link: "/reference/" },
            {
              text: "Ruby API reference",
              link: "https://fontist.org/fontist/reference/api-ruby/",
              target: "_self",
            },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/fontist/fontist" },
    ],

    footer: {
      message: `Fontist is <a href="https://open.ribose.com/">riboseopen</a>`,
      copyright: `Copyright &copy; 2023 Ribose Group Inc. All rights reserved.`,
    },
  },
});
