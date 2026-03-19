#!/bin/bash
set -e

BASE=/home/louis/Documents/knowledge-base
SRC=$BASE
W=$BASE/website
DOCS=$W/docs
I18N_CN=$W/i18n/zh-CN/docusaurus-plugin-content-docs/current
I18N_HK=$W/i18n/zh-HK/docusaurus-plugin-content-docs/current
STATIC=$W/static/files

# Clean defaults
rm -rf $W/docs/* $W/blog $W/src/components/HomepageFeatures

# Create directories
mkdir -p $DOCS/{deep-learning/fundamental,deep-learning/TrackNet,git-tutorial,python-tutorial,infra}
mkdir -p $I18N_CN/{deep-learning/fundamental,git-tutorial,python-tutorial,infra}
mkdir -p $I18N_HK/{deep-learning/fundamental,git-tutorial,python-tutorial,infra}
mkdir -p $STATIC/{cv,TrackNet/figures}

echo "=== Copying static files (PDFs, images) ==="
cp $SRC/deep_learning/cv/*.pdf $STATIC/cv/
cp $SRC/deep_learning/TrackNet/*.pdf $STATIC/TrackNet/
cp $SRC/deep_learning/TrackNet/figures/*.png $STATIC/TrackNet/figures/

echo "=== English docs (default locale) ==="
# deep-learning/fundamental
cp $SRC/deep_learning/fundamental/deep-learning-model-file.md $DOCS/deep-learning/fundamental/deep-learning-model-file.mdx

# deep-learning/TrackNet
cp $SRC/deep_learning/TrackNet/Readme.md $DOCS/deep-learning/TrackNet/Readme.mdx

# git-tutorial (English = -en suffix)
cp $SRC/git-tutorial/git-engineering-guide-en.md $DOCS/git-tutorial/git-engineering-guide.mdx
cp $SRC/git-tutorial/git-hooks-guide-en.md $DOCS/git-tutorial/git-hooks-guide.mdx
cp $SRC/git-tutorial/git-submodule-guide-en.md $DOCS/git-tutorial/git-submodule-guide.mdx

# python-tutorial (English = -en suffix)
cp $SRC/python-tutorial/python-engineering-guide-en.md $DOCS/python-tutorial/python-engineering-guide.mdx
cp $SRC/python-tutorial/pyproject-guide-en.md $DOCS/python-tutorial/pyproject-guide.mdx
cp $SRC/python-tutorial/uv-guide-en.md $DOCS/python-tutorial/uv-guide.mdx
cp $SRC/python-tutorial/python-tools-introduction-en.md $DOCS/python-tutorial/python-tools-introduction.mdx

# infra (English = base name, no lang suffix)
cp $SRC/infra/00-overview.md $DOCS/infra/overview.mdx
cp $SRC/infra/01-architecture-overview.md $DOCS/infra/architecture-overview.mdx
cp $SRC/infra/02-infrastructure-setup.md $DOCS/infra/infrastructure-setup.mdx
cp $SRC/infra/03-development-environment.md $DOCS/infra/development-environment.mdx
cp $SRC/infra/04-production-deployment.md $DOCS/infra/production-deployment.mdx
cp $SRC/infra/05-operations-troubleshooting.md $DOCS/infra/operations-troubleshooting.mdx
cp $SRC/infra/ssh.md $DOCS/infra/ssh.mdx
cp $SRC/infra/zero-trust-tutorial.md $DOCS/infra/zero-trust-tutorial.mdx

# Root-level
cp $SRC/RiskControl.md $DOCS/RiskControl.mdx

echo "=== Chinese Simplified (zh-CN) ==="
# deep-learning
cp $SRC/deep_learning/fundamental/deep-learning-model-file-zhCN.md $I18N_CN/deep-learning/fundamental/deep-learning-model-file.mdx

# git-tutorial
cp $SRC/git-tutorial/git-engineering-guide.md $I18N_CN/git-tutorial/git-engineering-guide.mdx
cp $SRC/git-tutorial/git-hooks-guide-zh-CN.md $I18N_CN/git-tutorial/git-hooks-guide.mdx
cp $SRC/git-tutorial/git-submodule-guide-zh-CN.md $I18N_CN/git-tutorial/git-submodule-guide.mdx

# python-tutorial
cp $SRC/python-tutorial/python-engineering-guide-zh-CN.md $I18N_CN/python-tutorial/python-engineering-guide.mdx
cp $SRC/python-tutorial/pyproject-guide-zh-CN.md $I18N_CN/python-tutorial/pyproject-guide.mdx
cp $SRC/python-tutorial/uv-guide-zh-CN.md $I18N_CN/python-tutorial/uv-guide.mdx
cp $SRC/python-tutorial/python-tools-introduction-zh-CN.md $I18N_CN/python-tutorial/python-tools-introduction.mdx

# infra
cp $SRC/infra/00-overview.zh-CN.md $I18N_CN/infra/overview.mdx
cp $SRC/infra/01-architecture-overview.zh-CN.md $I18N_CN/infra/architecture-overview.mdx
cp $SRC/infra/02-infrastructure-setup.zh-CN.md $I18N_CN/infra/infrastructure-setup.mdx
cp $SRC/infra/03-development-environment.zh-CN.md $I18N_CN/infra/development-environment.mdx
cp $SRC/infra/04-production-deployment.zh-CN.md $I18N_CN/infra/production-deployment.mdx
cp $SRC/infra/05-operations-troubleshooting.zh-CN.md $I18N_CN/infra/operations-troubleshooting.mdx
cp $SRC/infra/ssh.zh-CN.md $I18N_CN/infra/ssh.mdx

echo "=== Chinese Traditional (zh-HK) ==="
# git-tutorial
cp $SRC/git-tutorial/git-engineering-guide-zh-HK.md $I18N_HK/git-tutorial/git-engineering-guide.mdx
cp $SRC/git-tutorial/git-hooks-guide-zh-HK.md $I18N_HK/git-tutorial/git-hooks-guide.mdx
cp $SRC/git-tutorial/git-submodule-guide-zh-HK.md $I18N_HK/git-tutorial/git-submodule-guide.mdx

# python-tutorial
cp $SRC/python-tutorial/python-engineering-guide-zh-HK.md $I18N_HK/python-tutorial/python-engineering-guide.mdx
cp $SRC/python-tutorial/pyproject-guide-zh-HK.md $I18N_HK/python-tutorial/pyproject-guide.mdx
cp $SRC/python-tutorial/uv-guide-zh-HK.md $I18N_HK/python-tutorial/uv-guide.mdx
cp $SRC/python-tutorial/python-tools-introduction-zh-HK.md $I18N_HK/python-tutorial/python-tools-introduction.mdx

# infra
cp $SRC/infra/00-overview.zh-HK.md $I18N_HK/infra/overview.mdx
cp $SRC/infra/01-architecture-overview.zh-HK.md $I18N_HK/infra/architecture-overview.mdx
cp $SRC/infra/02-infrastructure-setup.zh-HK.md $I18N_HK/infra/infrastructure-setup.mdx
cp $SRC/infra/03-development-environment.zh-HK.md $I18N_HK/infra/development-environment.mdx
cp $SRC/infra/04-production-deployment.zh-HK.md $I18N_HK/infra/production-deployment.mdx
cp $SRC/infra/05-operations-troubleshooting.zh-HK.md $I18N_HK/infra/operations-troubleshooting.mdx
cp $SRC/infra/ssh.zh-HK.md $I18N_HK/infra/ssh.mdx

echo "=== Creating _category_.json files ==="

# English categories
cat > $DOCS/deep-learning/_category_.json << 'EOF'
{
  "label": "Deep Learning",
  "position": 1,
  "link": {"type": "generated-index"}
}
EOF

cat > $DOCS/git-tutorial/_category_.json << 'EOF'
{
  "label": "Git Tutorial",
  "position": 3,
  "link": {"type": "generated-index"}
}
EOF

cat > $DOCS/python-tutorial/_category_.json << 'EOF'
{
  "label": "Python Tutorial",
  "position": 2,
  "link": {"type": "generated-index"}
}
EOF

cat > $DOCS/infra/_category_.json << 'EOF'
{
  "label": "Infrastructure",
  "position": 4,
  "link": {"type": "generated-index"}
}
EOF

echo "Done!"
