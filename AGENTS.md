# AGENTS.md

This file contains context and instructions for AI agents working on the CustomRC repository.

## Project Overview
CustomRC breaks down monolithic shell configuration files (bashrc/zshrc) into manageable modules.
- **Root config**: `customrc.sh`
- **Modules**: Located in `rc-modules/` (Global, Darwin, Linux)
- **Repo path**: `~/.customrc`

## Architecture
- **Modular Design**: Functionality is split into specific files in `rc-modules/` (Global, Darwin, Linux).
- **Helpers**: Core logic in `helpers/`:
  - `logging.sh`: Output formatting.
  - `timing.sh`: Execution timing.
  - `cache.sh`: Centralized caching mechanism for expensive initializations.
- **Platform Specifics**: `Darwin/` for macOS, `Linux/` for Linux, `Global/` for shared.

## Development Workflow
- **File Deletion**: ALWAYS use `trash` instead of `rm`.
- **Search**: Use `ripgrep` (`rg`) or the Glob/Grep tools.
- **Pathing**: Always use absolute paths.
- **Performance**:
  - Use `./benchmark.sh` to evaluate startup time and compare against a monolithic build.
  - Target load times: Aliases < 2ms, Functions < 5ms, Cached completions < 10ms.
  - Refer to `docs/optimized-modules.md` for optimization patterns (lazy loading, caching).

## Code Style
- **Indentation**: 2 spaces.
- **Naming**: Descriptive variable names. SCREAMING_SNAKE_CASE for constants.
- **Comments**: Meaningful comments for complex logic.
- **Optimization**: Avoid subshells and expensive commands during initialization. Use `cache_init` for heavy tools.

## Git Instructions
- **Commits**: Follow Conventional Commits (feat, fix, docs, style, refactor, test, chore).
- **Messages**: Imperative mood, under 72 chars.

## Key Files
- `customrc.sh`: Main entry point.
- `helpers/cache.sh`: Caching utility.
- `benchmark.sh`: Performance testing tool.
- `docs/optimized-modules.md`: Optimization guide.
- `README.md`: Project documentation.
