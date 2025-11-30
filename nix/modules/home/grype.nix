# Grype vulnerability scanner configuration
#
# Migrated from chezmoi to home-manager xdg.configFile.
# Grype scans container images and filesystems for vulnerabilities.
{ config, lib, pkgs, ... }:

{
  xdg.configFile."grype/config.yaml".text = ''
    # Grype vulnerability scanner configuration

    # Output format: table, template, json, cyclonedx
    output: 'table'

    # Write to file (empty = stdout)
    file: '''

    # Pretty-print JSON output
    pretty: true

    # Generate CPEs for packages with no CPE data
    add-cpes-if-none: true

    # Check for updates on startup
    check-for-app-update: true

    # Filter settings
    only-fixed: false
    only-notfixed: false
    ignore-wontfix: 'wont-fix'

    # Sort results by severity
    sort-by: 'severity'

    # Search configuration
    search:
      scope: 'squashed'
      unindexed-archives: false
      indexed-archives: true

    # Ignore rules (empty by default)
    ignore: []

    # Exclude patterns
    exclude: []

    # External sources (disabled by default)
    external-sources:
      enable: false
      maven:
        search-maven-upstream: true
        base-url: 'https://search.maven.org/solrsearch/select'
        rate-limit: 300ms

    # Match settings per ecosystem
    match:
      java:
        using-cpes: false
      jvm:
        using-cpes: true
      dotnet:
        using-cpes: false
      golang:
        using-cpes: false
        always-use-cpe-for-stdlib: true
        allow-main-module-pseudo-version-comparison: false
      javascript:
        using-cpes: false
      python:
        using-cpes: false
      ruby:
        using-cpes: false
      rust:
        using-cpes: false
      stock:
        using-cpes: true

    # Registry settings
    registry:
      insecure-skip-tls-verify: false
      insecure-use-http: false
      auth: []
      ca-cert: '''

    # VEX documents
    vex-documents: []
    vex-add: []

    # Kernel header matching
    match-upstream-kernel-headers: true

    # Database settings
    db:
      cache-dir: '~/Library/Caches/grype/db'
      update-url: 'https://grype.anchore.io/databases'
      ca-cert: '''
      auto-update: true
      validate-by-hash-on-start: true
      validate-age: true
      max-allowed-built-age: 120h0m0s
      require-update-check: false
      update-available-timeout: 30s
      update-download-timeout: 5m0s
      max-update-check-frequency: 2h0m0s

    # Logging
    log:
      quiet: false
      level: 'warn'
      file: '''

    # Development options
    dev:
      profile: '''
      db:
        debug: false
  '';
}
