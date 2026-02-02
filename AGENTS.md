# AGENTS.md

This file contains context and instructions for AI agents working on the CustomRC repository.

## Project Overview
CustomRC breaks down monolithic shell configuration files (bashrc/zshrc) into manageable modules.
- **Root config**: `customrc.sh`
- **Modules**: Located in `rc-modules/` (Global, Darwin, Linux)
- **Repo path**: `~/.customrc`

## Architecture
- **Modular Design**: Functionality is split into specific files in `rc-modules/`.
- **Platform Specifics**: `Darwin/` for macOS, `Linux/` for Linux, `Global/` for shared.

## Development Workflow
- **File Deletion**: ALWAYS use `trash` instead of `rm`.
- **Search**: Use `ripgrep` (`rg`) or the Glob/Grep tools.
- **Pathing**: Always use absolute paths.

## Code Style
- **Indentation**: 2 spaces.
- **Naming**: Descriptive variable names. SCREAMING_SNAKE_CASE for constants.
- **Comments**: Meaningful comments for complex logic.

## Git Instructions
- **Commits**: Follow Conventional Commits (feat, fix, docs, style, refactor, test, chore).
- **Messages**: Imperative mood, under 72 chars.

## Key Files
- `customrc.sh`: Main entry point.
- `README.md`: Project documentation.
