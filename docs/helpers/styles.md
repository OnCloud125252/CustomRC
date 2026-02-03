# Styles Helper

The `styles.sh` helper provides ANSI color codes and status symbols for consistent terminal output formatting across CustomRC.

## Location

```
helpers/styles.sh
```

## Overview

This helper defines a standardized set of colors and symbols that other CustomRC components use for logging, status messages, and visual formatting. It's sourced early in the initialization process so all modules can use these constants.

## Colors

| Variable | Color | ANSI Code |
|----------|-------|-----------|
| `$RED` | Red | `\033[0;31m` |
| `$GREEN` | Green | `\033[0;32m` |
| `$YELLOW` | Yellow | `\033[0;33m` |
| `$BLUE` | Blue | `\033[0;34m` |
| `$PURPLE` | Purple | `\033[0;35m` |
| `$CYAN` | Cyan | `\033[0;36m` |
| `$WHITE` | White | `\033[0;37m` |
| `$NC` | No Color (reset) | `\033[0m` |

## Symbols

| Variable | Symbol | Description |
|----------|--------|-------------|
| `$CHECK` | `[✓]` | Success indicator (green) |
| `$CROSS` | `[✗]` | Failure indicator (red) |
| `$WARN` | `[!]` | Warning indicator (yellow) |
| `$INFO` | `[i]` | Information indicator (cyan) |

## Usage Examples

### Basic Color Output

```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error occurred${NC}"
echo -e "${YELLOW}Warning: check your config${NC}"
```

### Using Status Symbols

```bash
echo -e "${CHECK} Module loaded successfully"
echo -e "${CROSS} Failed to load module"
echo -e "${WARN} Configuration file not found"
echo -e "${INFO} Using default settings"
```

### Combining Colors and Symbols

```bash
echo -e "${CHECK} ${WHITE}Loaded:${NC} ${BLUE}mymodule.sh${NC}"
echo -e "${CROSS} ${WHITE}Ignored:${NC} ${BLUE}slow-module.sh${NC}"
```

## Integration

The styles helper is automatically sourced by `customrc.sh` before any modules load. You don't need to source it manually in your modules.

## See Also

- [logging.md](./logging.md) - Uses styles for formatted output
- [timing.md](./timing.md) - Uses colors for duration indicators
