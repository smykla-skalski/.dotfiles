# Lnav log file navigator configuration
#
# Migrated from chezmoi to home-manager home.file.
# Lnav is a terminal-based log file viewer with custom format support.
#
# Note: Lnav uses ~/.lnav directory for its configuration and formats.
{ config, lib, pkgs, ... }:

{
  # Main lnav config
  home.file.".lnav/config.json".text = builtins.toJSON {
    tuning = {
      external-editor = {
        impls = {
          RustRover = {
            prefers = "^.*(?:Cargo.toml|\\.rs)";
          };
        };
      };
    };
    ui = {
      theme = "monocai";
      theme-defs = {
        default = {
          highlights = {
            colors = {
              pattern = "(?:#[a-fA-F0-9]{6}|#[a-fA-F0-9]{3}\\b)";
            };
            ipv4 = {
              pattern = "\\b(?<!\\d\\.)\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b(?!\\.\\d)";
            };
            xml = {
              pattern = "</?([^ >=!]+)[^>]*>";
            };
            xml-decl = {
              pattern = "<!([^ >=!]+)[^>]*>";
            };
          };
        };
      };
    };
    log = {
      demux = {
        container = {
          pattern = "^(?:\\x1b\\[\\d*K)?(?<mux_id>[a-zA-Z0-9][\\@a-zA-Z0-9_\\.\\-]*)\\s+\\| (?<timestamp>\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}.\\d{9}Z )?(?<body>.*)";
        };
        container-with-type = {
          pattern = "^(?<mux_id>[a-zA-Z][\\w\\-]{3,}) (?<container_type>[a-zA-Z][\\w\\-]{3,}) (?<body>.*)";
        };
        recv-with-pod = {
          pattern = "^(?<timestamp>\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}(?:Z|[+\\-]\\d{2}:\\d{2})) source=[a-zA-Z0-9][a-zA-Z0-9_\\.\\-]* (?<body>.*) kubernetes_host=(?<k8s_host>[a-zA-Z0-9][a-zA-Z0-9_\\.\\-]*) kubernetes_pod_name=(?<mux_id>[a-zA-Z0-9][a-zA-Z0-9_\\.\\-]*)";
          control-pattern = "^===== (?:START|END) =====$";
        };
      };
    };
  };

  # Kuma log format (main)
  home.file.".lnav/formats/kuma/format.json".text = builtins.toJSON {
    "$schema" = "https://lnav.org/schemas/format-v1.schema.json";
    kuma_log = {
      title = "Kuma control-plane log";
      description = "Kuma components write tab-separated lines: <ts>\\t<level>\\t<logger>\\t<message>[\\t<json>]";
      file-pattern = ".*(kuma|kong-mesh)(-control-plane)?.*\\.log(\\.(txt|tsv))?$";
      regex = {
        main = {
          pattern = "^(?<ts>\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}[+-]\\d{4})\\t(?<level>[A-Z]+)\\t(?<logger>[^\\t]+)\\t(?<body>[^\t]*)(?:\\t(?<json>\\{.*\\}))?$";
        };
      };
      timestamp-field = "ts";
      timestamp-format = [ "%Y-%m-%dT%H:%M:%S.%L%z" ];
      level-field = "level";
      level = {
        fatal = "^FATAL$";
        critical = "^CRIT(?:ICAL)?$";
        error = "^ERROR$";
        warning = "^WARN(?:ING)?$";
        info = "^INFO$";
        debug = "^DEBUG$";
        trace = "^TRACE$";
      };
      value = {
        logger = {
          kind = "string";
          identifier = true;
        };
        json = {
          kind = "json";
        };
      };
      sample = [
        {
          line = "2025-07-27T12:44:46.446+0200\tINFO\tdp-server\thttp: TLS handshake error from 10.42.0.226:53012: EOF";
        }
        {
          line = "2025-07-27T12:44:48.226+0200\tINFO\txds.reconcile\tconfig has changed\t{\"proxyName\":\"kong-mesh-ingress-d9b497dcd-krt5m.kong-mesh-system\",\"mesh\":\"\",\"versions\":[\"b4f9d564-99e1-4134-8eb2-463bf4fb43ed\"]}";
        }
      ];
    };
  };

  # ECS Kuma control plane log format (CSV)
  home.file.".lnav/formats/installed/ecs_kuma_control_plane_log_csv.json".text = builtins.toJSON {
    "$schema" = "https://lnav.org/schemas/format-v1.schema.json";
    ecs_kuma_control_plane_logs = {
      title = "ECS Kuma/Kong Mesh control plane log / CSV";
      regex = {
        std = {
          pattern = "^(?<timestamp>[^,]+),(?<service_prefix>ecs\\/universalcontrolplane-services\\/)(?<service>[^,]+),(?<log_timestamp>[^,]+),(?<level>[^,]+),(?<logger>[^,]+),(?<message>[^,]+)(?:,(?<properties>.*))?$";
        };
      };
      multiline = true;
      ordered-by-time = false;
      timestamp-format = [ "%i" ];
      level-field = "level";
      level = {
        debug = "^DEBUG$";
        info = "^INFO$";
        warning = "^WARN$";
        error = "^ERROR$";
        fatal = "^FATAL$";
      };
      value = {
        service_prefix = {
          kind = "string";
          hidden = true;
        };
        service = {
          kind = "string";
          identifier = true;
        };
        log_timestamp = {
          kind = "string";
          hidden = true;
        };
        level = {
          kind = "string";
          identifier = true;
        };
        logger = {
          kind = "string";
          identifier = true;
        };
        message = {
          kind = "string";
        };
        properties = {
          kind = "json";
        };
      };
      sample = [
        {
          line = "1758999939984,ecs/universalcontrolplane-services/41b8e2de508b406e94c623205f0fe0dd,2025-09-27T19:05:39.984Z,DEBUG,opa-server,on tick,{\"streamID\": 377, \"node\": \"id:\\\"mobile-cuw-mesh.ip-10-37-146-117\\\" metadata:{fields:{key:\\\"features\\\" value:{list_value:{values:{string_value:\\\"configurable-decision-path\\\"}}}}}\"}\n";
        }
      ];
    };
  };

  # ECS Kuma control plane log format (JSON Lines)
  home.file.".lnav/formats/installed/ecs_kuma_control_plane_log_jsonlines.json".text = builtins.toJSON {
    "$schema" = "https://lnav.org/schemas/format-v1.schema.json";
    ecs_kuma_control_plane_logs_jsonlines = {
      title = "ECS Kuma/Kong Mesh control plane log / JSON Lines";
      file-type = "json";
      ordered-by-time = false;
      hide-extra = true;
      opid-field = "service_id";
      timestamp-field = "timestamp_ms";
      timestamp-format = [ "%i" ];
      level-field = "level";
      level = {
        debug = "DEBUG";
        info = "INFO";
        warning = "WARN";
        error = "ERROR";
        fatal = "FATAL";
      };
      line-format = [
        { field = "__timestamp__"; timestamp-format = "%H:%M:%S.%f"; }
        " "
        { field = "service_id"; overflow = "truncate"; max-width = 9; }
        " "
        { field = "level"; overflow = "truncate"; min-width = 5; max-width = 5; }
        " "
        { field = "logger"; auto-width = true; }
        " "
        { field = "message"; overflow = "truncate"; min-width = 72; max-width = 72; }
        " "
        { field = "context"; default-value = ""; }
      ];
      value = {
        timestamp_ms = { kind = "string"; };
        service_id = { kind = "string"; identifier = true; };
        iso_time = { kind = "string"; hidden = true; };
        level = { kind = "string"; identifier = true; };
        logger = { kind = "string"; identifier = true; };
        message = { kind = "string"; };
        context = { kind = "json"; };
      };
      sample = [
        {
          line = "{\"timestamp_ms\":\"1758999900170\",\"service_id\":\"41b8e2de508b406e94c623205f0fe0dd\",\"iso_time\":\"2025-09-27T19:05:00.170Z\",\"level\":\"DEBUG\",\"logger\":\"opa-server\",\"message\":\"on tick\",\"context\":{\"streamID\":616,\"node\":\"id:\\\"mobile-cuw-mesh.ip-10-37-150-90\\\" metadata:{fields:{key:\\\"features\\\" value:{list_value:{values:{string_value:\\\"configurable-decision-path\\\"}}}}}\"}}";
        }
      ];
    };
  };

  # Kuma control plane logs format (general)
  home.file.".lnav/formats/installed/kuma_control_plane_log.json".text = builtins.toJSON {
    "$schema" = "https://lnav.org/schemas/format-v1.schema.json";
    kuma_control_plane_logs = {
      title = "Kuma/Kong Mesh control plane log";
      regex = {
        std = {
          pattern = "^(?:(?<container>[^ ]+) (?<component>[^ ]+) )?(?<level_letter>[DIWEF])?(?<timestamp>\\d{4}[-\\/]\\d{2}[-\\/]\\d{2}[T ]\\d{2}:\\d{2}:\\d{2}(?:[,.]\\d{3}(?:Z|[-+]\\d{2}:?\\d{2})?)?|\\d{2}\\d{2}\\s+\\d{2}:\\d{2}:\\d{2}\\.\\d{6})(?:(?:\\t(?<level>DEBUG|INFO|WARN|ERROR|FATAL))?(?:[\\t ](?<logger>[^\\s:]+):?)[\\t ]|\\s+(?<pid>\\d+)\\s+(?<src_file>[^:]+):(?<src_line>\\d+)\\]\\s+)(?<body>.*?)(?:\\t(?<properties>\\{.*\\}))?$";
        };
      };
      multiline = true;
      ordered-by-time = false;
      timestamp-format = [
        "%Y-%m-%dT%H:%M:%S.%L%z"
        "%Y/%m/%d %H:%M:%S"
        "%m%d %H:%M:%S.%f"
      ];
      level-field = "level";
      level = {
        debug = "^DEBUG$";
        info = "^INFO$";
        warning = "^WARN$";
        error = "^ERROR$";
        fatal = "^FATAL$";
      };
      value = {
        timestamp = { kind = "string"; };
        container = { kind = "string"; identifier = true; };
        component = { kind = "string"; identifier = true; hidden = true; };
        logger = { kind = "string"; identifier = true; };
        level = { kind = "string"; identifier = true; };
        body = { kind = "string"; };
        properties = { kind = "json"; };
        pid = { kind = "integer"; identifier = true; hidden = true; };
        src_file = { kind = "string"; identifier = true; };
        src_line = { kind = "integer"; foreign-key = true; };
        level_letter = { kind = "string"; hidden = true; };
      };
      sample = [
        { line = "2025-07-27T12:44:46.446+0200\tINFO\tdp-server\thttp: TLS handshake error from 10.42.0.226:53012: EOF"; }
        { line = "2025-07-27T12:44:46.519+0200\tINFO\tkds-zone\tdetected changes in the resources. Sending changes to the client.\t{\"streamID\": 2, \"nodeID\": \"kuma-1\", \"resourceType\": \"MeshService\", \"client\": \"global\"}"; }
      ];
    };
  };
}
