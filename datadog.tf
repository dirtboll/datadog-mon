resource "kubernetes_namespace" "datadog_system" {
  metadata {
    name = "datadog-system"
  }
}

resource "kubernetes_secret" "datadog_secret" {
  metadata {
    name      = "datadog-secret"
    namespace = kubernetes_namespace.datadog_system.metadata[0].name
  }
  data = {
    api-key = var.datadog_k8s_controller_api_key
  }
}

resource "kubernetes_secret" "datadog_database_password" {
  metadata {
    name = "datadog-database-password"
    namespace = kubernetes_namespace.datadog_system.metadata[0].name
  }
  data = {
    password = random_password.datadog.result
  }
}

resource "helm_release" "datadog_agent" {
  name              = "datadog-agent"
  repository        = "https://helm.datadoghq.com"
  chart             = "datadog"
  atomic            = true
  dependency_update = true
  namespace         = kubernetes_namespace.datadog_system.metadata[0].name
  values = [yamlencode({
    datadog = {
      secretBackend = {
        command = "/readsecret_multiple_providers.sh"
      }
      apiKeyExistingSecret = kubernetes_secret.datadog_secret.metadata[0].name
      site                 = "us5.datadoghq.com"
      apm = {
        instrumentation = {
          enabled = true
        }
      }
      criSocketPath = "/run/dockershim.sock"
      env = [{
        name  = "DD_AUTOCONFIG_INCLUDE_FEATURES"
        value = "containerd"
      }]
    }
    clusterAgent = {
      admissionController = {
        mutateUnlabelled = false
      }
      confd = {
        "postgres.yaml" = <<-EOT
          cluster_check: true
          init_config:
          instances:
          - dbm: true
            host: ${aws_db_instance.default.address}
            port: ${aws_db_instance.default.port}
            username: ${postgresql_role.datadog.name}
            password: 'ENC[k8s_secret@${kubernetes_secret.datadog_database_password.metadata[0].namespace}/${kubernetes_secret.datadog_database_password.metadata[0].name}/password]'
            tags:
              - 'dbinstanceidentifier:default'
        EOT
      }
    }
    clusterChecksRunner = {
      enabled = true
    }
  })]
}

# Postgres Monitor

resource "random_password" "datadog" {
  length           = 16
  special          = true
  override_special = "_%-{}+"
}

resource "postgresql_role" "datadog" {
  name     = "datadog"
  login    = true
  password = random_password.datadog.result
  roles = [
    "pg_monitor"
  ]
}

resource "postgresql_schema" "postgres_datadog" {
  name     = "datadog"
  database = "postgres"
  policy {
    usage = true
    role  = postgresql_role.datadog.name
  }
}

resource "postgresql_grant" "postgres_datadog_usage" {
  database    = "postgres"
  role        = postgresql_role.datadog.name
  schema      = postgresql_schema.postgres_datadog.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "postgres_public_usage" {
  database    = "postgres"
  role        = postgresql_role.datadog.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant_role" "pg_monitor_datadog" {
  role       = postgresql_role.datadog.name
  grant_role = "pg_monitor"
}

resource "postgresql_extension" "pg_stat_statements" {
  name     = "pg_stat_statements"
  database = "postgres"
  schema   = "public"
}

resource "postgresql_function" "datadog_explain_statement" {
    name = "explain_statement"
    database = "postgres"
    schema = postgresql_schema.postgres_datadog.name
    arg {
        mode = "IN"
        name = "l_query"
        type = "text"
    }
    arg {
      name = "explain"
      type = "json"
      mode = "OUT"
    }
    returns = "SETOF json"
    language = "plpgsql"
    body = <<-EOF
        DECLARE
        curs REFCURSOR;
        plan JSON;

        BEGIN
          OPEN curs FOR EXECUTE pg_catalog.concat('EXPLAIN (FORMAT JSON) ', l_query);
          FETCH curs INTO plan;
          CLOSE curs;
          RETURN QUERY SELECT plan;
        END;
    EOF
    security_definer = true
}
