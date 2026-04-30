# `qmllint-plugins.sh`

This repository uses [`qmllint-plugins.sh`](./qmllint-plugins.sh) as a wrapper
around Qt's `qmllint` for Noctalia plugins.

The wrapper exists because plugin QML imports Noctalia shell modules such as
`qs.Commons`, `qs.Widgets`, and `qs.Services.*`. A plain `qmllint` run does not
know how to resolve those imports in this repo layout.

## Why the wrapper exists

Running `qmllint` directly on a plugin file in this repo usually is not enough.
Plugin QML imports modules from the vendored Noctalia shell source tree:

- `qs.Commons`
- `qs.Widgets`
- `qs.Services.*`
- `qs.Helpers`

Those are not installed system-wide QML modules. They live in
`docs/noctalia-shell`, and the repo does not ship ready-made `qmldir` metadata
for every import path in a shape that `qmllint` can consume directly for plugin
checks.

The wrapper solves that by building a temporary import tree that looks like the
module layout the plugins expect.

## High-level flow

At a high level, the script:

1. Parses explicit targets from `--plugin`, `--dir`, and `--file`.
2. Rejects bad inputs early:
   - missing paths
   - paths outside the workspace
   - non-`.qml` file targets
   - `--dir` / `--file` targets that are not inside a plugin root
3. Expands the requested scope into a de-duplicated list of QML files.
4. Groups the selected files by plugin root, where a plugin root is any
   directory containing `manifest.json`.
5. Creates a temporary import shim tree under `/tmp/noctalia-qmllint.*`.
6. Generates `qmldir` files and symlinks Noctalia shell sources from
   `docs/noctalia-shell` into that shim tree.
7. Runs `qmllint` once per plugin group with:
   - `-I <temporary shim root>`
   - `-I <plugin root>`
   - `-W 0`
   - `--json <temporary raw result file>`
8. Rewrites each raw `qmllint` result into a richer per-plugin report.
9. Aggregates all plugin reports into one top-level JSON object.

## Target resolution and grouping

The first part of the script is about turning user input into a safe, explicit
set of files.

### Path validation

All target paths are normalized with `realpath` and must remain inside the repo
root. The script rejects:

- missing paths
- paths outside the workspace
- plugin targets that are not directories
- plugin targets without `manifest.json`
- directory targets outside a plugin root
- file targets that are not `.qml`
- file targets outside a plugin root

The plugin-root rule matters because linting is done with one `qmllint` run per
plugin. A plugin root is identified by walking upward until a `manifest.json`
is found.

### File collection

After validation:

- `--plugin` expands to every `.qml` file under that plugin directory
- `--dir` expands to every `.qml` file under that subdirectory
- `--file` contributes exactly one file

The script de-duplicates all selected files before linting. That means repeated
targets or overlapping `--plugin` and `--file` inputs do not produce duplicate
lint work.

### Grouping by plugin

Even if a command selects files from multiple plugins, the script does not run
one giant `qmllint` invocation. Instead it groups the files by plugin root and
stores one file list per plugin.

That matters for imports because each `qmllint` call gets:

- the temporary shim root
- the specific plugin root being linted

The plugin root is added with `-I <plugin_root>`, so local imports inside that
plugin resolve relative to the correct plugin directory instead of some other
selected plugin.

## How import setup works

The import setup is the core of the wrapper.

### Temporary root

For each run, the script creates a temporary directory:

```text
/tmp/noctalia-qmllint.XXXXXX
```

Inside it, the script builds a synthetic module tree rooted at:

```text
<tmp>/qs
```

### Modules the wrapper creates

The wrapper creates these module paths:

- `<tmp>/qs/Commons`
- `<tmp>/qs/Widgets`
- `<tmp>/qs/Services/<service>`
- `<tmp>/qs/Services/<service>/<submodule>`
- `<tmp>/qs/Commons/<submodule>`
- `<tmp>/qs/Widgets/<submodule>`

It also symlinks:

- `<tmp>/qs/Helpers` -> `docs/noctalia-shell/Helpers`

The services, commons submodules, and widgets submodules are discovered
dynamically by scanning `docs/noctalia-shell`.

### `qmldir` generation

For each generated module directory, the script writes a `qmldir` file. This is
what allows `qmllint` to treat the symlinked source files as a proper QML
module.

Each generated `qmldir` starts with:

```text
module <module name>
```

Then the script enumerates every `*.qml` file in the source directory and emits
one type line per file:

- `TypeName 1.0 File.qml`
- or `singleton TypeName 1.0 File.qml` when the file's first line is
  `pragma Singleton`

This singleton detection is important because `qmllint` needs the module
metadata to match the real QML type semantics. If a singleton were emitted as a
normal type, import resolution and linting behavior would diverge from runtime.

### Why symlinks are used

The wrapper does not copy the Noctalia shell QML files into `/tmp`. It creates
symlinks to the real files instead. That keeps setup cheap and ensures linting
sees the actual vendored source tree, not a stale copy.

### Import paths passed to `qmllint`

Each per-plugin `qmllint` invocation gets:

- `-I <tmp_root>`
- `-I <plugin_root>`

`-I <tmp_root>` makes `qs.*` imports resolvable because the synthetic tree
contains `qs/Commons`, `qs/Widgets`, and `qs/Services/...`.

`-I <plugin_root>` makes plugin-local imports resolvable, for example when a
plugin imports one of its own sibling components.

The wrapper also forces JSON output and immediate failure-on-findings behavior
with:

- `--json <result file>`
- `-W 0`

`-W 0` means any warning count greater than zero yields a non-zero exit code
from `qmllint`.

## Per-plugin lint execution

For each plugin group, the script:

1. Writes the selected file list to `<tmp>/files.<plugin>.txt`
2. Reads that file list back into a Bash array
3. Chooses `<tmp>/result.<plugin>.json` as the raw `qmllint` output path
4. Runs `qmllint` once with the file array appended as positional inputs

Using one run per plugin instead of one run per file has two benefits:

- local intra-plugin imports resolve correctly with one plugin-specific `-I`
- output remains grouped in a way that maps cleanly back to the repo's plugin
  structure

## Report building

The wrapper does not expose raw `qmllint` JSON directly as its only output. It
transforms the raw results into a more useful report shape with `jq`.

### Raw `qmllint` structure

The raw JSON is stored under each result's `qmllint` field. In practice the
important part is:

- `.files[]`
- each file entry has `filename`, `success`, and `warnings`

### Flattened diagnostics

The wrapper extracts every warning from every file and flattens them into a
single `diagnostics[]` array per plugin. Each entry contains:

- `plugin`
- `filename`
- `line`
- `column`
- `id`
- `message`
- `severity`

`severity` is copied from `qmllint`'s warning `type` field.

This flattened shape is much easier to consume from scripts, CI glue, or review
tools than the original nested `files[].warnings[]` layout.

### Derived counts

The wrapper also derives:

- `warningCount`
- `severityCounts`
- `warningCountsById`

Those counts are computed from the flattened diagnostics array, not from the raw
exit code alone. That means the report remains useful even when you want counts
and categories instead of only pass/fail.

### Aggregate output

After all plugin groups are processed, the script combines the per-plugin report
files into one top-level JSON object with:

- overall selected file count
- overall plugin-group count
- pass/fail totals
- `results[]` containing each plugin report

That aggregated object is what default stdout JSON prints, and it is also what
`--json-file` writes to disk.

## Environment requirements

The wrapper expects:

- `docs/noctalia-shell` with `Commons` and `Widgets`
- `jq`
- Qt6 `qmllint` at `/usr/lib/qt6/bin/qmllint` or on `PATH`

If any dependency is missing, the script exits with a descriptive error.

## Failure behavior

The wrapper exits non-zero when any plugin group has findings.

That behavior is based on the final derived report:

- if a plugin's `lintPassed` is false, it counts as failed
- if any plugin group failed, the wrapper exits `1`

This makes the script suitable both for manual local checks and for automated
quality gates.

## Practical debugging notes

If a plugin unexpectedly fails to lint because of missing imports, the most
useful places to inspect are:

- whether `docs/noctalia-shell` contains the module being imported
- whether that module directory has `*.qml` files for the wrapper to expose
- whether the selected file is grouped under the expected plugin root
- whether the import is plugin-local and therefore depends on the correct
  `-I <plugin_root>`

If you need machine-readable output for deeper debugging, use:

```bash
./scripts/qmllint-plugins.sh --file <path>.qml --json-file /tmp/qmllint.json
```

Then inspect both:

- `results[].diagnostics`
- `results[].qmllint`
