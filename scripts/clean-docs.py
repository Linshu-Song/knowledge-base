#!/usr/bin/env python3
"""Clean up docs: remove language selection links, manual TOC, fix internal links."""

import re
import os
import glob

BASE = "/home/louis/Documents/knowledge-base/website"

# File rename mapping: old filename (without .md) -> new filename (without .md)
FILE_MAP = {
    "00-overview": "overview",
    "01-architecture-overview": "architecture-overview",
    "02-infrastructure-setup": "infrastructure-setup",
    "03-development-environment": "development-environment",
    "04-production-deployment": "production-deployment",
    "05-operations-troubleshooting": "operations-troubleshooting",
    "git-hooks-guide-en": "git-hooks-guide",
    "git-hooks-guide-zh-CN": "git-hooks-guide",
    "git-hooks-guide-zh-HK": "git-hooks-guide",
    "git-submodule-guide-en": "git-submodule-guide",
    "git-submodule-guide-zh-CN": "git-submodule-guide",
    "git-submodule-guide-zh-HK": "git-submodule-guide",
    "pyproject-guide-en": "pyproject-guide",
    "pyproject-guide-zh-CN": "pyproject-guide",
    "pyproject-guide-zh-HK": "pyproject-guide",
    "uv-guide-en": "uv-guide",
    "uv-guide-zh-CN": "uv-guide",
    "uv-guide-zh-HK": "uv-guide",
    "python-tools-introduction-en": "python-tools-introduction",
    "python-tools-introduction-zh-CN": "python-tools-introduction",
    "python-tools-introduction-zh-HK": "python-tools-introduction",
    "deep-learning-model-file-zhCN": "deep-learning-model-file",
    "00-overview.zh-CN": "overview",
    "00-overview.zh-HK": "overview",
    "01-architecture-overview.zh-CN": "architecture-overview",
    "01-architecture-overview.zh-HK": "architecture-overview",
    "02-infrastructure-setup.zh-CN": "infrastructure-setup",
    "02-infrastructure-setup.zh-HK": "infrastructure-setup",
    "03-development-environment.zh-CN": "development-environment",
    "03-development-environment.zh-HK": "development-environment",
    "04-production-deployment.zh-CN": "production-deployment",
    "04-production-deployment.zh-HK": "production-deployment",
    "05-operations-troubleshooting.zh-CN": "operations-troubleshooting",
    "05-operations-troubleshooting.zh-HK": "operations-troubleshooting",
    "ssh.zh-CN": "ssh",
    "ssh.zh-HK": "ssh",
}


def remove_language_selection(content: str) -> str:
    """Remove Language Selection / 语言选择 sections."""
    # Pattern: ## Language Selection (or ## 语言选择) followed by lines until ---
    pattern = r"\n## (?:Language Selection|语言選擇|语言选择)\n+(?:- \[?.*?\]?\(.*?\).*?\n)+\n*---\n"
    content = re.sub(pattern, "\n", content)
    # Also handle without trailing ---
    pattern2 = (
        r"\n## (?:Language Selection|语言選擇|语言选择)\n+(?:- \[?.*?\]?\(.*?\).*?\n)+"
    )
    content = re.sub(pattern2, "\n", content)
    return content


def remove_toc(content: str) -> str:
    """Remove Table of Contents / 目录 sections."""
    # Pattern: # Table of Contents or ## Table of Contents
    # Followed by numbered/bulleted links
    # May or may not have trailing ---
    pattern = r"\n#(?:#)? (?:Table of Contents|目錄|目录)\n+(?:[-\d]+\.? \[.*?\]\(#.*?\).*?\n)+(?:\n*---\n)?"
    content = re.sub(pattern, "\n", content)
    return content


def fix_internal_links(content: str) -> str:
    """Fix internal markdown links to use new filenames."""
    for old, new in FILE_MAP.items():
        # Fix (old.md) links
        content = content.replace(f"({old}.md)", f"({new}.md)")
        # Fix links with ./ prefix
        content = content.replace(f"(./{old}.md)", f"(./{new}.md)")

    # Remove back-to-knowledge-base links
    content = re.sub(
        r"\n*\[.*?Back to Knowledge Base.*?\]\(\.\./README\.md\)\n*", "\n", content
    )
    content = re.sub(r"\n*\[.*?返回知识库.*?\]\(\.\./README.*?\.md\)\n*", "\n", content)

    return content


def process_file(filepath: str):
    """Process a single markdown file."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original = content
    content = remove_language_selection(content)
    content = remove_toc(content)
    content = fix_internal_links(content)

    # Clean up multiple blank lines
    content = re.sub(r"\n{4,}", "\n\n\n", content)

    if content != original:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  FIXED: {os.path.relpath(filepath, BASE)}")
    else:
        print(f"  OK:    {os.path.relpath(filepath, BASE)}")


def main():
    # Find all .md files in docs/ and i18n/
    patterns = [
        os.path.join(BASE, "docs/**/*.md"),
        os.path.join(BASE, "i18n/**/*.md"),
    ]

    for pattern in patterns:
        for filepath in sorted(glob.glob(pattern, recursive=True)):
            # Skip _category_.json and sidebars
            if "_category_" in filepath or "sidebar" in filepath:
                continue
            process_file(filepath)

    print("\nDone!")


if __name__ == "__main__":
    main()
