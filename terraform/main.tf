locals {
  app_tags = merge({Name = var.app_name}, var.default_tags)
  region = "eu-west-1"
  test_script_url = join("/", ["s3:/", "${aws_s3_bucket.results.bucket}", var.test_script])
}

provider "aws" {
  profile = "default"
  region  = local.region
}

/* 
Define a service role for the ec2 batch executor instances, 
attach the appropriate policy, and wrap it in a profile for the 
batch compute enfironment. 
*/
resource "aws_iam_role" "instance" {
  name               = "${var.app_name}_instance_role"
  assume_role_policy = <<EOF
{ 
    "Version": "2012-10-17", 
    "Statement": [ 
    { 
        "Action": "sts:AssumeRole", 
        "Effect": "Allow", 
        "Principal": { 
        "Service": "ec2.amazonaws.com" 
        } 
    } 
    ] 
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.instance.name
}

resource "aws_iam_instance_profile" "instance" {
  name = var.app_name
  role = aws_iam_role.instance.name
}

resource "aws_iam_role" "batch" {
  name               = "${var.app_name}_batch"
  assume_role_policy = <<EOF
{ 
    "Version": "2012-10-17", 
    "Statement": [ 
    { 
        "Action": "sts:AssumeRole", 
        "Effect": "Allow", 
        "Principal": { 
        "Service": "batch.amazonaws.com" 
        } 
    } 
    ] 
}
EOF
}

resource "aws_iam_role_policy_attachment" "batch" {
  role = aws_iam_role.batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"

}

/* 
Define a service role for the ecs task, 
attach the appropriate policy, and wrap it in a profile for the 
batch compute enfironment. 
*/
resource "aws_iam_role" "task" {
  name               = "${var.app_name}_task"
  assume_role_policy = <<EOF
{ 
    "Version": "2012-10-17", 
    "Statement": [ 
    { 
        "Action": "sts:AssumeRole", 
        "Effect": "Allow", 
        "Principal": { 
        "Service": "ecs-tasks.amazonaws.com" 
        } 
    } 
    ] 
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_RW" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.task.name
}

resource "aws_launch_template" "batch_node_lt" {
  name = var.app_name
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 40
    }
  }
  ebs_optimized = false
  image_id = var.ami_id
  instance_initiated_shutdown_behavior = "terminate"
  key_name = var.key_name
  vpc_security_group_ids = var.sg_ids
  tag_specifications {
    resource_type = "instance"
    tags = local.app_tags
  }
  tag_specifications {
    resource_type = "volume"
    tags = local.app_tags
  }
}

resource "aws_s3_bucket" "results" {
  bucket = "${var.app_name}-batch-results"
  acl    = "private"
  region = var.region
  versioning {
    enabled = false
  }
}

resource "aws_batch_compute_environment" "primary" {
  compute_environment_name = "${var.app_name}_primary"
  compute_resources {
    launch_template {
      launch_template_id = aws_launch_template.batch_node_lt.id
    }
    instance_role = aws_iam_instance_profile.instance.arn
    instance_type = var.instance_types
    security_group_ids = var.sg_ids
    subnets = var.subnets
    tags = local.app_tags
    #Spot Capacity 
    type = "SPOT"
    allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"
    bid_percentage = 100
    #Cluster resource limits 
    max_vcpus = 24
    desired_vcpus = 4
    min_vcpus = 4
  }
  service_role = aws_iam_role.batch.arn
  type = "MANAGED"
  depends_on = [aws_iam_role_policy_attachment.batch]
}

resource "aws_batch_job_queue" "primary" {
  name = var.app_name
  state = "ENABLED"
  priority = 100
  compute_environments = [aws_batch_compute_environment.primary.arn]
}

resource "aws_batch_job_definition" "primary" {
  name = "${var.app_name}_primary"
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["far"],
    "image": "${var.container_image}",
    "memory": ${var.task_memory},
    "vcpus":  ${var.task_vcpus},
    "jobRoleArn": "${aws_iam_role.task.arn}",
    "volumes": [
      {
        "host": {
          "sourcePath": "/tmp"
        },
        "name": "tmp"
      }
    ],
    "environment": [
        {
            "name": "BATCH_FILE_S3_URL",
            "value": "${local.test_script_url}"
        },
        {
            "name": "BATCH_FILE_TYPE",
            "value": "script"
        }
    ],
    "mountPoints": [
        {
          "sourceVolume": "tmp",
          "containerPath": "/tmp",
          "readOnly": false
        }
    ],
    "ulimits": [
      {
        "hardLimit": 1024,
        "name": "nofile",
        "softLimit": 1024
      }
    ]
}
CONTAINER_PROPERTIES
}