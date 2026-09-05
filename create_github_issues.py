#!/usr/bin/env python3
"""
Create GitHub issues from GITHUB_ISSUES.md
Usage: GH_TOKEN=ghp_xxx python3 create_github_issues.py
"""
import os
import re
import sys
import requests

REPO = "nexuslinux-os/NexusLinux"
API = f"https://api.github.com/repos/nexuslinux-os/NexusLinux/issues"

def parse_issues(md_file):
    with open(md_file, "r") as f:
        content = f.read()

    # Pattern to match issues
    pattern = r'### #(\d+)\s+(.*?)\n\*\*Labels:\*\*\s+(.*?)\n\*\*File[s]?:\*\*\s+(.*?)\n\*\*Detail:\*\*(.*?)\n\*\*Fix:\*\*(.*?)(?=\n### #|\Z)'
    matches = re.findall(r'### #(\d+)\s+(.*?)\n\*\*Labels:\*\*\s+(.*?)\n\*\*File[s]?:\*\*\s+(.*?)\n\*\*Detail:\*\*(.*?)\n\*\*Fix:\*\*(.*?)(?=\n### #|\Z)', 
                         content, re.DOTALL)
    
    issues = []
    for num, title, labels, files, detail, fix in matches:
        labels_list = [l.strip() for l in labels.split(",")]
        body = f"""**File(s):** {files.strip()}

**Detail:** {detail.strip()}

**Fix:** {fix.strip()}

---
*Auto-created from GITHUB_ISSUES.md*"""
        
        issues.append({
            "number": num,
            "title": f"#{num} {title.strip()}",
            "body": body,
            "labels": [l.strip() for l in labels.split(",")]
        })
    return issues

def create_issue(issue, token):
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json",
    }
    data = {
        "title": issue["title"],
        "body": issue["body"],
        "labels": issue["labels"]
    }
    r = requests.post(f"https://api.github.com/repos/nexuslinux-os/NexusLinux/issues", 
                      headers={"Authorization": f"token {TOKEN}", "Accept": "application/vnd.github+json"}, 
                      json=data)
    return r

if __name__ == "__main__":
    TOKEN = os.environ.get("GH_TOKEN")
    if not TOKEN:
        print("Error: Set GH_TOKEN environment variable")
        print("Usage: GH_TOKEN=ghp_xxx python3 create_github_issues.py")
        sys.exit(1)

    issues = parse_issues("GITHUB_ISSUES.md")
    print(f"Found {len(issues)} issues to create")

    for issue in issues:
        print(f"Creating issue {issue['number']}: {issue['title']}...")
        # We need to use the proper token variable
        import os
        TOKEN = os.environ.get("GH_TOKEN")
        r = requests.post(
            f"https://api.github.com/repos/nexuslinux-os/NexusLinux/issues",
            headers={"Authorization": f"token {TOKEN}", "Accept": "application/vnd.github+json"},
            json={"title": issue["title"], "body": issue["body"], "labels": issue["labels"]}
        )
        if r.status_code == 201:
            print(f"  ✅ Created: {issue['title']}")
        else:
            print(f"  ❌ Failed ({r.status_code}): {r.text}")

    print("Done!")