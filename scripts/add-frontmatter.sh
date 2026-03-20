#!/bin/bash
set -e

W=/home/louis/Documents/knowledge-base/website
DOCS=$W/docs
I18N_CN=$W/i18n/zh-CN/docusaurus-plugin-content-docs/current
I18N_HK=$W/i18n/zh-HK/docusaurus-plugin-content-docs/current

# Function to add frontmatter if not present
add_frontmatter() {
  local file="$1"
  local pos="$2"
  # Check if file already starts with ---
  if head -1 "$file" | grep -q "^---$"; then
    echo "SKIP (has frontmatter): $file"
    return
  fi
  # Create temp file with frontmatter prepended
  local tmp="${file}.tmp"
  printf -- "---\nsidebar_position: %d\n---\n\n" "$pos" > "$tmp"
  cat "$file" >> "$tmp"
  mv "$tmp" "$file"
  echo "OK: $file (position: $pos)"
}

# --- deep-learning ---
add_frontmatter "$DOCS/deep-learning/fundamental/deep-learning-model-file.md" 1
add_frontmatter "$DOCS/deep-learning/TrackNet/Readme.md" 2

# --- python-tutorial ---
add_frontmatter "$DOCS/python-tutorial/python-engineering-guide.md" 1
add_frontmatter "$DOCS/python-tutorial/pyproject-guide.md" 2
add_frontmatter "$DOCS/python-tutorial/uv-guide.md" 3
add_frontmatter "$DOCS/python-tutorial/python-tools-introduction.md" 4

# --- git-tutorial ---
add_frontmatter "$DOCS/git-tutorial/git-engineering-guide.md" 1
add_frontmatter "$DOCS/git-tutorial/git-hooks-guide.md" 2
add_frontmatter "$DOCS/git-tutorial/git-submodule-guide.md" 3

# --- infra ---
add_frontmatter "$DOCS/infra/overview.md" 1
add_frontmatter "$DOCS/infra/architecture-overview.md" 2
add_frontmatter "$DOCS/infra/infrastructure-setup.md" 3
add_frontmatter "$DOCS/infra/development-environment.md" 4
add_frontmatter "$DOCS/infra/production-deployment.md" 5
add_frontmatter "$DOCS/infra/operations-troubleshooting.md" 6
add_frontmatter "$DOCS/infra/ssh.md" 7
add_frontmatter "$DOCS/infra/zero-trust-tutorial.md" 8

# --- root ---
add_frontmatter "$DOCS/RiskControl.md" 5

echo ""
echo "=== zh-CN ==="

add_frontmatter "$I18N_CN/deep-learning/fundamental/deep-learning-model-file.md" 1
[ -f "$I18N_CN/deep-learning/TrackNet/Readme.md" ] && add_frontmatter "$I18N_CN/deep-learning/TrackNet/Readme.md" 2

add_frontmatter "$I18N_CN/python-tutorial/python-engineering-guide.md" 1
add_frontmatter "$I18N_CN/python-tutorial/pyproject-guide.md" 2
add_frontmatter "$I18N_CN/python-tutorial/uv-guide.md" 3
add_frontmatter "$I18N_CN/python-tutorial/python-tools-introduction.md" 4

add_frontmatter "$I18N_CN/git-tutorial/git-engineering-guide.md" 1
add_frontmatter "$I18N_CN/git-tutorial/git-hooks-guide.md" 2
add_frontmatter "$I18N_CN/git-tutorial/git-submodule-guide.md" 3

add_frontmatter "$I18N_CN/infra/overview.md" 1
add_frontmatter "$I18N_CN/infra/architecture-overview.md" 2
add_frontmatter "$I18N_CN/infra/infrastructure-setup.md" 3
add_frontmatter "$I18N_CN/infra/development-environment.md" 4
add_frontmatter "$I18N_CN/infra/production-deployment.md" 5
add_frontmatter "$I18N_CN/infra/operations-troubleshooting.md" 6
add_frontmatter "$I18N_CN/infra/ssh.md" 7

echo ""
echo "=== zh-HK ==="

[ -f "$I18N_HK/deep-learning/fundamental/deep-learning-model-file.md" ] && add_frontmatter "$I18N_HK/deep-learning/fundamental/deep-learning-model-file.md" 1
[ -f "$I18N_HK/deep-learning/TrackNet/Readme.md" ] && add_frontmatter "$I18N_HK/deep-learning/TrackNet/Readme.md" 2

add_frontmatter "$I18N_HK/python-tutorial/python-engineering-guide.md" 1
add_frontmatter "$I18N_HK/python-tutorial/pyproject-guide.md" 2
add_frontmatter "$I18N_HK/python-tutorial/uv-guide.md" 3
add_frontmatter "$I18N_HK/python-tutorial/python-tools-introduction.md" 4

add_frontmatter "$I18N_HK/git-tutorial/git-engineering-guide.md" 1
add_frontmatter "$I18N_HK/git-tutorial/git-hooks-guide.md" 2
add_frontmatter "$I18N_HK/git-tutorial/git-submodule-guide.md" 3

add_frontmatter "$I18N_HK/infra/overview.md" 1
add_frontmatter "$I18N_HK/infra/architecture-overview.md" 2
add_frontmatter "$I18N_HK/infra/infrastructure-setup.md" 3
add_frontmatter "$I18N_HK/infra/development-environment.md" 4
add_frontmatter "$I18N_HK/infra/production-deployment.md" 5
add_frontmatter "$I18N_HK/infra/operations-troubleshooting.md" 6
add_frontmatter "$I18N_HK/infra/ssh.md" 7

echo ""
echo "Done!"
