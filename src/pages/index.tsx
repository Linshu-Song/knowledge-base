import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

const SectionList = [
  {
    title: 'Deep Learning',
    description: 'Computer Vision (YOLO series, CNN), object tracking (TrackNet), and fundamental concepts.',
    link: '/docs/deep-learning/fundamental/deep-learning-model-file',
    emoji: '🤖',
  },
  {
    title: 'Python Tutorial',
    description: 'Modern Python development practices, packaging with pyproject.toml, UV, and code quality tools.',
    link: '/docs/python-tutorial/python-engineering-guide',
    emoji: '🐍',
  },
  {
    title: 'Git Tutorial',
    description: 'Git engineering best practices, hooks with Husky/Commitizen, and submodules guide.',
    link: '/docs/git-tutorial/git-engineering-guide',
    emoji: '📚',
  },
  {
    title: 'Infrastructure',
    description: 'Architecture overview, Docker setup, dev environments, deployment, operations, and SSH.',
    link: '/docs/infra',
    emoji: '🏗️',
  },
];

function SectionCard({title, description, link, emoji}: (typeof SectionList)[number]) {
  return (
    <div className={clsx('col col--6', styles.cardCol)}>
      <Link to={link} className={styles.card}>
        <Heading as="h3">
          {emoji} {title}
        </Heading>
        <p>{description}</p>
      </Link>
    </div>
  );
}

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Knowledge Base" description="Internal knowledge base for SAILTECHTEAM">
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {SectionList.map((props, idx) => (
                <SectionCard key={idx} {...props} />
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
