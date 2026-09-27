# Offline tests with a mocked AWS provider.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "555555555555"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  delivery_bucket_name = "harbor-goods-log-archive-444455556666"
  delivery_kms_key_arn = "arn:aws:kms:us-east-1:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab"
}

run "records_everything_to_the_archive" {
  command = plan

  assert {
    condition     = one(aws_config_configuration_recorder.this.recording_group).all_supported
    error_message = "The recorder must record every supported resource type."
  }

  assert {
    condition     = one(aws_config_configuration_recorder.this.recording_group).include_global_resource_types
    error_message = "The home region records global resources."
  }

  assert {
    condition     = aws_config_delivery_channel.this.s3_bucket_name == "harbor-goods-log-archive-444455556666"
    error_message = "Deliveries must go to the central archive."
  }

  assert {
    condition     = aws_config_configuration_recorder_status.this.is_enabled
    error_message = "The recorder must be started."
  }

  assert {
    condition     = length(aws_iam_service_linked_role.config) == 1
    error_message = "The service-linked role is created by default."
  }
}

run "secondary_region_skips_global_resources" {
  command = plan

  variables {
    record_global_resources    = false
    create_service_linked_role = false
    recording_frequency        = "DAILY"
  }

  assert {
    condition     = !one(aws_config_configuration_recorder.this.recording_group).include_global_resource_types
    error_message = "Only one region per account records global resources."
  }

  assert {
    condition     = aws_config_configuration_recorder.this.role_arn == "arn:aws:iam::555555555555:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
    error_message = "An existing service-linked role is referenced by its fixed ARN."
  }
}

run "rejects_unknown_frequency" {
  command = plan

  variables {
    recording_frequency = "HOURLY"
  }

  expect_failures = [var.recording_frequency]
}
