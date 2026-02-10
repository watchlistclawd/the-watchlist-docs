# TOON - Token-Oriented Object Notation

Data format optimized for LLM token efficiency. 30-60% reduction vs JSON.

## Core Principles

1. **Indentation-based hierarchy** — No curly braces. Nesting via whitespace (like Python/YAML).

2. **Tabular arrays** — Define keys once as header, values as rows:
   ```
   items[3]{id,name,price}:
     1,Widget,9.99
     2,Gadget,19.99
     3,Gizmo,14.99
   ```

3. **No repeated keys** — The biggest JSON waste. Header declares schema once.

4. **Minimal punctuation** — No quotes around keys, no colons between k/v pairs.

5. **Count in header** — `[3]` indicates array length upfront.

## Format Reference

```toon
# Simple object
user:
  name: John
  age: 30

# Array of objects (tabular)
logs[2]{timestamp,level,message}:
  "2025-01-01T00:00:00Z",info,Started
  "2025-01-01T00:01:00Z",error,Failed

# Nested
franchise:
  name: Attack on Titan
  entries[1]{id,title,episodes}:
    1,Shingeki no Kyojin,25
```

## When to Use

- Sending structured data to LLMs (prompts, context)
- Large uniform arrays (logs, products, entries)
- Batch API requests

## When NOT to Use

- API responses (clients expect JSON)
- Config files (use YAML/TOML)
- Human editing (JSON more familiar)

## Library

```bash
npm install toon
```

```typescript
import { encode } from 'toon';
const toon = encode(jsonData);
```

GitHub: https://github.com/toon-format/toon
