#!/usr/bin/env python3
"""Pattern 4: Fine-grained progress bar with true color gradient"""
import json, sys, subprocess, os

data = json.load(sys.stdin)

BLOCKS = ' ▏▎▍▌▋▊▉█'
R = '\033[0m'
DIM = '\033[2m'
CYAN = '\033[36m'
GREEN = '\033[32m'

def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'
    else:
        g = int(200 - (pct - 50) * 4)
        return f'\033[38;2;255;{max(g,0)};60m'

def bar(pct, width=10):
    pct = min(max(pct, 0), 100)
    filled = pct * width / 100
    full = int(filled)
    frac = int((filled - full) * 8)
    b = '█' * full
    if full < width:
        b += BLOCKS[frac]
        b += '░' * (width - full - 1)
    return b

def fmt(label, pct):
    p = round(pct)
    return f'{label} {gradient(pct)}{bar(pct)} {p}%{R}'

def get_git_branch(cwd):
    try:
        result = subprocess.run(
            ['git', 'branch', '--show-current'],
            cwd=cwd, capture_output=True, text=True, timeout=3,
            env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'}
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None

def get_github_pr(cwd):
    try:
        result = subprocess.run(
            ['gh', 'pr', 'view', '--json', 'number,state', '--jq', '"\(.number)|\(.state)"'],
            cwd=cwd, capture_output=True, text=True, timeout=5,
            env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'}
        )
        if result.returncode == 0:
            parts = result.stdout.strip().split('|', 1)
            if len(parts) == 2:
                return {'number': parts[0], 'state': parts[1]}
    except Exception:
        pass
    return None

cwd = data.get('workspace', {}).get('current_dir') or data.get('cwd', os.getcwd())
branch = get_git_branch(cwd)
pr_info = get_github_pr(cwd) if branch else None

model = data.get('model', {}).get('display_name', 'Claude')
header_parts = [model]
if branch:
    header_parts.append(f'{CYAN}{branch}{R}')
if pr_info:
    state_color = GREEN if pr_info['state'].upper() == 'OPEN' else DIM
    header_parts.append(f'{state_color}PR#{pr_info["number"]}{R}')

header = ' '.join(header_parts)
lines = [f' {header} ']

ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    lines.append(f' {fmt("ctx", ctx)} ')

five = data.get('rate_limits', {}).get('five_hour', {}).get('used_percentage')
if five is not None:
    lines.append(f' {fmt("5h", five)} ')

week = data.get('rate_limits', {}).get('seven_day', {}).get('used_percentage')
if week is not None:
    lines.append(f' {fmt("7d", week)} ')

print('\n'.join(lines), end='')
