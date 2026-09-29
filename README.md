# engram-desktop

native macos menu bar companion and daemon supervisor for [engram](https://github.com/Unbound-Cognition/engram).

## why this exists

engram is a local cognitive daemon. it runs over stdio or loopback http, but running terminal daemons manually or setting up custom launchd plists gets annoying.

i built engram-desktop to give engram a lightweight native shell on macos:
- lives in the menu bar with status, memory count, and direct controls
- supervises the local engram process (start, stop, auto-restart on crash)
- one-click config wiring for claude code, codex, cursor, and antigravity
- floating recall hud (spotlight-style) to query your cognitive store from anywhere

## features

### daemon supervisor
monitors the local python daemon running on `127.0.0.1:8420`. streams stdout/stderr into a live log view and keeps the process alive across reboots.

### agent auto-wiring
detects installed agent harnesses and registers engram as an mcp server automatically:
- claude code (`~/.claude.json`)
- codex (`~/.codex/config.json`)
- cursor (`~/.cursor/mcp.json`)
- antigravity / gemini (`~/.gemini/antigravity-cli/mcp/`)

no manual editing of nested json config files.

### quick recall hud
hit `⌘⇧M` (or click recall hud) to bring up a floating search bar. runs 5-channel hybrid retrieval across your episodic, semantic, and procedural memories with instant preview and copy.

### zero-knowledge sync
monitor local ChaCha20-Poly1305 sync key status, check Lamport sequence numbers, add/remove peer nodes, and trigger encrypted peer-to-peer replication passes directly from the menu bar.

## install

download the latest signed release from [github releases](https://github.com/Unbound-Cognition/engram-desktop/releases/latest):

```bash
# unzip and move to Applications
unzip Engram-0.1.2-arm64.zip
mv Engram.app /Applications/
```

## building

requires macos 14.0+ and swift 6.0+.

```bash
# build debug binary
make build

# build release app bundle (Engram.app)
make bundle
```

the bundle will be output to `dist/arm64/Engram.app`.

## license

MIT
