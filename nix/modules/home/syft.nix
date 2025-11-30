# Syft SBOM generator configuration
#
# Migrated from chezmoi to home-manager xdg.configFile.
# Syft generates Software Bill of Materials (SBOM) for container images and filesystems.
{ config, lib, pkgs, ... }:

{
  xdg.configFile."syft/config.yaml".text = ''
    # Syft SBOM generator configuration

    # Logging
    log:
      quiet: false
      verbosity: 0
      level: 'warn'
      file: '''

    # Development options
    dev:
      profile: '''

    # Output format(s)
    output:
      - 'syft-table'

    # Legacy file output (empty = stdout)
    legacyFile: '''

    # Format options
    format:
      pretty: true
      template:
        path: '''
        legacy: false
      json:
        legacy: false
      spdx-json: {}
      cyclonedx-json: {}
      cyclonedx-xml: {}

    # Check for updates
    check-for-app-update: true

    # Cataloger settings
    catalogers: []
    default-catalogers: []
    select-catalogers: []

    # Package search options
    package:
      search-unindexed-archives: false
      search-indexed-archives: true
      exclude-binary-overlap-by-ownership: true

    # License settings
    license:
      content: 'none'
      coverage: 75

    # File metadata
    file:
      metadata:
        selection: 'owned-by-package'
        digests:
          - 'sha1'
          - 'sha256'
      content:
        skip-files-above-size: 256000
        globs: []
      executable:
        globs: []

    # Scan scope
    scope: 'squashed'

    # Parallelism (0 = auto, based on CPU count)
    parallelism: 0

    # Relationship tracking
    relationships:
      package-file-ownership: true
      package-file-ownership-overlap: true

    # Compliance settings
    compliance:
      missing-name: 'drop'
      missing-version: 'stub'

    # Data enrichment (disabled by default)
    enrich: []

    # .NET settings
    dotnet:
      dep-packages-must-have-dll: false
      dep-packages-must-claim-dll: true
      propagate-dll-claims-to-parents: true
      relax-dll-claims-when-bundling-detected: true

    # Go settings
    golang:
      search-local-mod-cache-licenses: true
      local-mod-cache-dir: '~/go/pkg/mod'
      search-local-vendor-licenses: true
      local-vendor-dir: '''
      search-remote-licenses: true
      proxy: 'https://proxy.golang.org,direct'
      no-proxy: '''
      main-module-version:
        from-ld-flags: true
        from-contents: false
        from-build-settings: true

    # Java settings
    java:
      maven-local-repository-dir: '~/.m2/repository'
      maven-url: 'https://repo1.maven.org/maven2'
      max-parent-recursive-depth: 0
      resolve-transitive-dependencies: false

    # JavaScript settings
    javascript:
      search-remote-licenses: true
      npm-base-url: '''

    # Linux kernel settings
    linux-kernel:
      catalog-modules: true

    # Nix settings
    nix:
      capture-owned-files: false

    # Python settings
    python:
      guess-unpinned-requirements: false

    # Registry settings
    registry:
      insecure-skip-tls-verify: false
      insecure-use-http: false
      auth: []
      ca-cert: '''

    # Source settings
    from: []
    platform: '''

    source:
      name: '''
      version: '''
      base-path: '''
      file:
        digests:
          - 'SHA-256'
      image:
        default-pull-source: '''
        max-layer-size: '''

    # Exclude patterns
    exclude: []

    # Unknown handling
    unknowns:
      remove-when-packages-defined: true
      executables-without-packages: true
      unexpanded-archives: true

    # Cache settings
    cache:
      dir: '~/Library/Caches/syft'
      ttl: '7d'

    # Debug settings
    show-hidden: false

    # Attestation settings
    attest:
      key: '''
      password: '''
  '';
}
