import path from 'path';
import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';

const config: Config = {
  title: 'Knowledge Base',
  tagline: 'Internal knowledge base for SAILTECHTEAM',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
    experimental_faster: {
      swcJsLoader: true,
      swcJsMinimizer: true,
      swcHtmlMinimizer: true,
      lightningCssMinimizer: true,
      rspackBundler: true,
      rspackPersistentCache: true,
      ssgWorkerThreads: true,
      mdxCrossCompilerCache: true,
    },
  },

  url: 'https://sailtechteam.github.io',
  baseUrl: '/knowledge-base/',

  organizationName: 'SAILTECHTEAM',
  projectName: 'knowledge-base',

  onBrokenLinks: 'warn',
  onBrokenAnchors: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'zh-CN', 'zh-HK'],
    localeConfigs: {
      en: {label: 'English'},
      'zh-CN': {label: '简体中文'},
      'zh-HK': {label: '繁體中文'},
    },
  },

  markdown: {
    mermaid: true,
    format: 'detect',
  },

  themes: ['@docusaurus/theme-mermaid'],

  plugins: [
    function vscodeLanguageserverAliasPlugin() {
      return {
        name: 'vscode-languageserver-alias-plugin',
        configureWebpack() {
          return {
            resolve: {
              alias: {
                'vscode-languageserver-types': path.resolve(
                  __dirname,
                  'node_modules/vscode-languageserver-types/lib/esm/main.js',
                ),
              },
            },
          };
        },
      };
    },
  ],

  stylesheets: [],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/SAILTECHTEAM/knowledge-base/tree/main/',
          remarkPlugins: [remarkMath],
          rehypePlugins: [rehypeKatex],
          showLastUpdateTime: true,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Knowledge Base',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          type: 'localeDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/SAILTECHTEAM/knowledge-base',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Sections',
          items: [
            {label: 'Deep Learning', to: '/docs/deep-learning/fundamental'},
            {label: 'Python Tutorial', to: '/docs/python-tutorial/python-engineering-guide'},
            {label: 'Git Tutorial', to: '/docs/git-tutorial/git-engineering-guide'},
            {label: 'Infrastructure', to: '/docs/infra/architecture-overview'},
          ],
        },
        {
          title: 'More',
          items: [
            {label: 'GitHub', href: 'https://github.com/SAILTECHTEAM/knowledge-base'},
          ],
        },
      ],
      copyright: `Copyright \u00a9 ${new Date().getFullYear()} SAILTECHTEAM. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
