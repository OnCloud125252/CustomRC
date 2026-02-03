# Timing Helper

The `timing.sh` helper provides functions for measuring and displaying execution times during CustomRC initialization.

## Location

```
helpers/timing.sh
```

## Overview

This helper enables performance measurement of module loading times. It provides millisecond-precision timing and color-coded duration feedback to help identify slow modules.

## Functions

### `get_duration_ms`

Calculates elapsed time in milliseconds from a start timestamp.

```bash
get_duration_ms <start_time> <result_var>
```

**Parameters:**
- `start_time` - Nanosecond timestamp from `$(date +%s%N)`
- `result_var` - Variable name to store the result

**Usage:**
```bash
local start_time=$(date +%s%N)
# ... do work ...
local duration
get_duration_ms $start_time duration
echo "Took ${duration}ms"
```

### `get_duration_color`

Returns an ANSI color code based on individual file load duration.

```bash
get_duration_color <duration_ms> <result_var>
```

**Parameters:**
- `duration_ms` - Duration in milliseconds
- `result_var` - Variable name to store the color code

**Thresholds:**
| Duration | Color | Meaning |
|----------|-------|---------|
| < 10ms | Green | Fast (optimal) |
| 10-50ms | Yellow | Acceptable |
| > 50ms | Red | Slow (needs optimization) |

**Usage:**
```bash
local color
get_duration_color 25 color
echo -e "${color}${duration}ms${NC}"
```

### `get_total_duration_color`

Returns an ANSI color code based on total initialization duration.

```bash
get_total_duration_color <duration_ms> <result_var>
```

**Parameters:**
- `duration_ms` - Total duration in milliseconds
- `result_var` - Variable name to store the color code

**Thresholds:**
| Duration | Color | Meaning |
|----------|-------|---------|
| < 1000ms | Green | Fast startup |
| 1000-2000ms | Yellow | Acceptable |
| > 2000ms | Red | Slow (needs optimization) |

## Performance Targets

Based on the timing thresholds, aim for:

| Metric | Target |
|--------|--------|
| Individual module | < 10ms |
| Total initialization | < 1000ms |

## Usage Example

```bash
#!/usr/bin/env zsh

# Start timing
local start=$(date +%s%N)

# Load modules
source "$HOME/.customrc/customrc.sh"

# Calculate and display duration
local duration color
get_duration_ms $start duration
get_total_duration_color $duration color

echo -e "CustomRC loaded in ${color}${duration}ms${NC}"
```

## How It Works

The timing functions use nanosecond precision from `date +%s%N` and convert to milliseconds using integer arithmetic:

```bash
# Conversion formula
duration_ms = (end_time - start_time) / 1000000
```

This avoids floating-point operations for better performance.

## See Also

- [styles.md](./styles.md) - Color definitions used by timing functions
- [../optimized-modules.md](../optimized-modules.md) - Performance optimization guide
