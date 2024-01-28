import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  ignoreDeadLinks: true,

  title: "Fontist",
  description:
    "Fontist brings cross-platform font management to the command line for Windows, Linux, and macOS. Free and open source.",

    // https://github.com/vuejs/vitepress/issues/3508
  base: process.env.BASE_URL
    ? new URL(process.env.BASE_URL).pathname
    : undefined,

  // https://vitepress.dev/reference/default-theme-config
  themeConfig: {
    logo: { src: "/logo.png" },

    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/" },
      { text: "Reference", link: "/reference/" },
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
              link: "https://fontist.org/formulas/",
            }, // TODO: Put formulas webiste "Create formula" guide here
          ],
        },
        {
          text: "API",
          items: [
            { text: "Fontist Ruby library", link: "/guide/api-ruby" },
            { text: "Ruby API reference", link: "/reference/api-ruby/" },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            { text: "Fontist CLI reference", link: "/reference/" },
            { text: "Ruby API reference", link: "/reference/api-ruby/" },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/fontist/fontist" },
    ],

    footer: {
      copyright: `\
Fontist is <a href="https://open.ribose.com/"><img alt="riboseopen" style="display: inline; height: 28px" valign=middle src="${process.env.BASE_URL || ""}riboseopen.png" /></a><br />
Copyright &copy; 2023 Ribose Group Inc. All rights reserved.<br />
<a href="https://www.ribose.com/tos">Terms of Service</a> | <a href="https://www.ribose.com/privacy">Privacy Policy</a>`,
    },
  },
});
