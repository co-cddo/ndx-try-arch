import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import {execSync} from 'child_process';

// Get build info
const gitSha = process.env.GITHUB_SHA || execSync('git rev-parse HEAD').toString().trim();
const gitShaShort = gitSha.slice(0, 7);
const buildDate = new Date().toISOString().split('T')[0];

const config: Config = {
  title: 'NDX Architecture',
  tagline: 'NDX Innovation Sandbox Platform Documentation',
  favicon: 'img/favicon.ico',

  url: 'https://co-cddo.github.io',
  baseUrl: '/ndx-try-arch/',

  organizationName: 'co-cddo',
  projectName: 'ndx-try-arch',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  markdown: {
    mermaid: true,
  },

  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/co-cddo/ndx-try-arch/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    navbar: {
      title: 'NDX Architecture',
      logo: {
        alt: 'NDX Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/co-cddo/ndx-try-arch',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Overview',
              to: '/docs/',
            },
            {
              label: 'Architecture',
              to: '/docs/80-c4-architecture',
            },
          ],
        },
        {
          title: 'Resources',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/co-cddo/ndx-try-arch',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Government Digital Service (GDS), DSIT. Built ${buildDate} from <a href="https://github.com/co-cddo/ndx-try-arch/tree/${gitSha}">${gitShaShort}</a>.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'json', 'yaml', 'typescript'],
    },
    mermaid: {
      theme: {
        light: 'neutral',
        dark: 'dark',
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
