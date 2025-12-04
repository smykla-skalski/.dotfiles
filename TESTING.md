# Testing

Automated testing ensures shell scripts have correct syntax, configuration files are valid, and linters pass quality checks.

## Running Tests

```bash
task test           # Run all tests
task lint           # Run all linters
```

## Individual Test Suites

```bash
task test:fish          # Test Fish config loads
task test:shell         # Check shell script syntax
task test:shellspec     # Run ShellSpec tests
task test:brewfile      # Validate Brewfile

task lint:shell         # Shellcheck linting
task lint:fish          # Fish syntax check
task lint:markdown      # Markdown linting
task lint:taskfile      # Validate Taskfile schema
task lint:actions       # Lint GitHub Actions workflows
```

## CI/CD

Tests run automatically on every push via GitHub Actions on:

- **Ubuntu 24.04**: Linux compatibility
- **macOS 15**: macOS compatibility

Workflow validates:

1. Shell syntax and linting
2. Configuration file validity
3. Fish configuration loading
4. Age encryption/decryption

See [`.github/workflows/test.yaml`](.github/workflows/test.yaml) for details.

## Writing Tests

### ShellSpec Tests

Tests go in `spec/` directory:

```bash
spec/
├── taskfile_spec.sh        # Taskfile command tests
└── support/               # Test helpers
```

Run with:

```bash
task test:shellspec
```

### Adding Linter Checks

Add to appropriate task in `Taskfile.yaml`:

```yaml
lint:custom:
  desc: Lint custom files
  cmds:
    - my-linter files/**/*
```

Then add to main `lint` task deps.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and debugging techniques.
