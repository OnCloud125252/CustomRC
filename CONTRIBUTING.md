# Contributing to CustomRC

Thank you for your interest in contributing to CustomRC! This document provides guidelines and information for contributors.

## Code of Conduct

Be respectful and constructive in all interactions. We welcome contributors of all experience levels.

## How to Contribute

### Reporting Issues

Before opening an issue, please:

1. Check existing issues to avoid duplicates
2. Use the issue templates if available
3. Include relevant information:
   - Your shell (bash/zsh) and version
   - Your OS (macOS/Linux) and version
   - Steps to reproduce the issue
   - Expected vs actual behavior

### Submitting Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the code style guidelines below
3. **Test your changes** by sourcing the modified files
4. **Run the benchmark** to ensure no performance regressions:
   ```bash
   ./benchmark.sh
   ```
5. **Commit your changes** using conventional commits (see below)
6. **Open a pull request** with a clear description of the changes

## Code Style Guidelines

### Shell Scripts

- Use 2 spaces for indentation (not tabs)
- Use `SCREAMING_SNAKE_CASE` for constants
- Use `snake_case` for function names and local variables
- Add meaningful comments for complex logic
- Avoid subshells and expensive commands during initialization

### Performance Considerations

CustomRC prioritizes fast shell startup. When contributing:

- Use lazy loading for expensive initializations
- Leverage the caching system (`helpers/cache.sh`) for slow commands
- Avoid running external commands during module load when possible
- Test performance with `./benchmark.sh`

Target load times:
- Aliases: < 2ms
- Functions: < 5ms
- Cached completions: < 10ms

### Documentation

- Update relevant documentation when changing functionality
- Use clear, concise language
- Include examples where helpful

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

[optional body]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat: add lazy loading for nvm initialization
fix: correct path detection on Apple Silicon Macs
docs: add troubleshooting section to user guide
perf: reduce fzf module load time by 50%
```

## Development Workflow

1. **Clone the repository**:
   ```bash
   git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc-dev
   ```

2. **Create a test environment**:
   ```bash
   # Create test modules
   cp -r rc-modules.example rc-modules
   ```

3. **Enable debug mode** for development:
   ```bash
   # In configs.sh or export directly
   export CUSTOMRC_DEBUG_MODE=true
   ```

4. **Test changes**:
   ```bash
   # Source the configuration
   source customrc.sh

   # Run benchmark
   ./benchmark.sh
   ```

## Project Structure

```
customrc/
├── customrc.sh           # Main entry point
├── configs.sh            # Configuration and ignore lists
├── install.sh            # Installation script
├── benchmark.sh          # Performance testing
├── helpers/              # Core utilities
│   ├── cache.sh          # Caching system
│   ├── monolithic.sh     # Production mode generator
│   ├── loader.sh         # Debug mode loader
│   ├── logging.sh        # Output formatting
│   ├── timing.sh         # Timing utilities
│   └── styles.sh         # Color definitions
├── rc-modules.example/   # Template modules (tracked)
│   ├── Global/           # Cross-platform
│   ├── Darwin/           # macOS-specific
│   └── Linux/            # Linux-specific
├── rc-modules/           # User modules (gitignored)
└── docs/                 # Documentation
```

## Questions?

If you have questions about contributing, feel free to:
- Open a discussion on GitHub
- Check the [documentation](docs/)

Thank you for contributing!
