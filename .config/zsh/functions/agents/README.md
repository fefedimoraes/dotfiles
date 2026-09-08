# Agent adapters

One file per AI coding-agent CLI, sourced by `../agents.zsh`. Drop a new file in
and it is picked up — nothing else needs editing.

## Minimum viable adapter

```zsh
_agents_register mycli glyph='󱚝' label='mycli' bin='mycli' comms='mycli'
```

That is enough for `prefix + a` to find a running `mycli` in any tmux pane, show
whether it is busy or idle, jump to it and kill it. The generic discovery path
needs no knowledge of the CLI beyond the name its process reports, so this works
for a CLI nobody has written an integration for.

`comms` is an ERE matched against a process's **argv0 basename**, anchored by the
core. Use it when the process name differs from the id, or when a CLI has been
renamed and both names are still in the wild — `mycli-cli|mycli`. For a CLI
launched through a runtime the basename may be `node` or `bun`, in which case the
generic scan cannot tell it apart and you need `_enrich` below.

## Optional hooks

All are looked up by name; define only what you can verify against real data.

| Hook                                      | Emits                                                           | Purpose                                                 |
| ----------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------- |
| `_agents_<id>_enrich`                     | `E<TAB>pane<TAB>status<TAB>name<TAB>session_id<TAB>since_epoch` | Decorates rows the process scan already found           |
| `_agents_<id>_history`                    | `session_id<TAB>cwd<TAB>mtime<TAB>title`                        | Rows for `prefix + A`                                   |
| `_agents_<id>_resume <session_id> <cwd>`  | a shell command                                                 | How to resume; required for Enter in the history picker |
| `_agents_<id>_preview <session_id> <cwd>` | text                                                            | Transcript preview                                      |
| `_agents_<id>_fork_flag`                  | a flag                                                          | Appended on `alt-enter`                                 |

### `_enrich` decorates, it never discovers

Returning rows from `_enrich` for panes the process scan did not find does
nothing. This is deliberate. A CLI that maintains its own session registry makes
that file look like the ideal source — it may even record tmux coordinates — but
such a registry can be absent, empty or stale while its agents are running.
Anything built on it alone then answers "no agents" while several are mid-task,
which is the worst possible failure for a tool whose only job is telling you where
your agents are. So `ps` decides what exists and `_enrich` only adds detail.

Join on `pane`, and report the **leaf** pid of the process chain — the one with no
matched child — because that is what the core keys on. Validate liveness with
`kill -0`; registry entries tend to outlive their processes.

### `status` is an open vocabulary

Emit whatever string the CLI uses. The core ranks `waiting` (needs you) above
`idle` above unknown above `busy`, and anything it does not recognise gets a
neutral `?` rather than being coerced. A CLI that grows a new state keeps working.

Where no `_enrich` supplies a status, the core samples the pane twice ~0.5s apart
and calls it busy if anything changed. Cheaper signals were tried and rejected —
see the notes at the top of `../agents.zsh`.

### `_history` should be cheap on repeat calls

The picker calls it on every open and refresh, so a full scan of a session store
that grows without bound will be felt. Where metadata has to be parsed out of
transcripts, cache on each file's mtime and re-parse only what changed — usually
nothing. Where a session store keeps its metadata in top-level keys, one pass over
it is already cheap and no cache is warranted. Either way, use the file's mtime as
the session's age instead of parsing a timestamp.

Sanitise titles: strip tabs and newlines, and note that `jq`'s `@tsv` turns a
real tab into the two characters `\t`, so both forms need removing or the field
count shifts and the machine fields stop lining up.

## Unresumable rows are shown, not hidden

An adapter whose `bin` cannot be found still lists its history, dimmed and marked
`(not installed)`; Enter reports why rather than silently doing nothing. A CLI that
has been uninstalled, or moved to a machine that never had it, leaves its sessions
readable — and a row you cannot act on is information, whereas an empty list looks
like a bug.

## Adding a CLI

Adding support for another CLI is one file. Start from **Minimum viable adapter**
above, which already buys live discovery, then add the optional hooks as you can
verify each against real sessions — the on-disk format is the part worth being
careful about, since guessing at it produces an adapter that appears to work and
silently lists nothing.
