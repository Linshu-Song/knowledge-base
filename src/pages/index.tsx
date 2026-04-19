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
    link: '/docs/deep-learning/fundamental/',
  },
  {
    title: 'Python Tutorial',
    description: 'Modern Python engineering practices and toolsets.',
    link: '/docs/python-tutorial/',
  },
  {
    title: 'Git Tutorial',
    description: 'Standardized Git workflows for professional teams.',
    link: '/docs/git-tutorial/',
  },
  {
    title: 'Infrastructure',
    description: 'Cloud-native architecture and development environments.',
    link: '/docs/infra/architecture-overview',
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
        <h1 className="hero__title">
          {siteConfig.title}
        </h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Knowledge Base" description="Internal knowledge base for SAILTECHTEAM">
      <div className="disable_numbered_headings">
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
      </div>
    </Layout>
  );
}
