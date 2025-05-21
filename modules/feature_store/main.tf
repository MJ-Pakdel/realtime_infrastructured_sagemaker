resource "aws_sagemaker_feature_group" "this" {
  # ------------------------------------------------------------------
  feature_group_name             = var.feature_group_name   # e.g. real_time_features
  record_identifier_feature_name = var.record_id_name       # -> "id"
  event_time_feature_name        = var.event_time_name      # -> "event_ts"
  role_arn                       = var.role_arn
  # ------------------------------------------------------------------

  # ------------ required feature definitions -----------------------
  feature_definition {
    feature_name = var.record_id_name
    feature_type = "String"
  }

  feature_definition {
    feature_name = var.event_time_name
    feature_type = "String"
  }

  # ---- eight synthetic feature columns from make_regression() -----
  feature_definition {
    feature_name = "f1"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f2"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f3"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f4"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f5"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f6"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f7"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "f8"
    feature_type = "Fractional"
  }

  # ------------ store configs stay exactly the same ----------------
  online_store_config {
    enable_online_store = true
  }

  offline_store_config {
    s3_storage_config { s3_uri = var.offline_s3_uri }
  }
}
