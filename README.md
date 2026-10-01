# homebrew-tap

Homebrew tap for [simple-english](https://github.com/TonyCTHsu/simple-english).

```bash
brew install TonyCTHsu/tap/simple-english
```

The formula installs the gem under Homebrew's own Ruby, plus OpenJDK
17. Nothing else is needed on the machine. The daemon downloads the
pinned LanguageTool on first start; run `se setup` to do it ahead of
time, or `brew services start simple-english` to keep a warm daemon.

Updating a release: bump the `url`/`sha256` and any changed resource
gems. The commit is conventionally `simple-english <old> -> <new>`.
