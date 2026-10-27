# Cross-platform shell configuration
# Use PowerShell on Windows (higher precedence than shell setting)
[windows]
set shell := ["powershell.exe", "-NoLogo", "-Command"]

export VIRTUAL_ENV := ".venv"

alias ta := test-all
alias tca := test-coverage-all

prek := "uv run --frozen --only-group prek prek"
pytest := "uv run --frozen --only-group test pytest"

[private]
default:
    @just --list --unsorted --list-heading $'commands…\n'

# Sync the dev environment and install git hooks
init:
    uv sync --group dev --all-extras
    {{ prek }} install

# Run hooks on all files (every hook when none are given)
check *hooks:
    {{ prek }} run --all-files --show-diff-on-failure --color=always {{ hooks }}

# Ruff format + check, spelling (codespell, typos)
lint: (check "ruff-format" "ruff-check" "codespell" "typos")

# Mypy, ty, bandit, semgrep
static-analysis: (check "mypy" "ty" "bandit" "semgrep")

# Run tests
test-all +args="tests/":
    {{ pytest }} {{ args }}

# Run tests with coverage
test-coverage-all +args="tests/":
    {{ pytest }} {{ args }} --cov --cov-context=test --cov-report=term:skip-covered

# Run benchmarks
bench:
    @uv run --frozen --no-dev --group benchmarks pytest benchmarks/ --codspeed
