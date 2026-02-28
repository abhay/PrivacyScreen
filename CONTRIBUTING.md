# Contributing

Thanks for your interest in PrivacyScreen! This is a small project and contributions are welcome.

## Getting started

1. Fork the repo and clone it locally
2. Build and run tests to make sure everything works:
   ```bash
   xcodebuild test -scheme PrivacyScreen \
     -destination 'platform=iOS Simulator,name=iPhone 16' -quiet
   ```
3. Pre-commit hooks (SwiftFormat + SwiftLint) run automatically via lefthook

## How to contribute

- **Bug reports** — open an issue with steps to reproduce
- **Feature ideas** — open an issue to discuss before writing code
- **Pull requests** — keep them focused on a single change; include tests for new behavior

## Code style

- Run `lefthook run pre-commit` to auto-format and lint before committing
- Use Swift Testing (`@Test`, `#expect`) not XCTest

## Note

This project was developed with the assistance of AI coding tools (Claude Code). Contributions from humans and AI-assisted workflows are both welcome.
