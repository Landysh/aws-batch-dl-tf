/* 
This variables file can be used to customize the batch executor deployment. 
Starting with the very high level details:
*/
variable "app_name" {
    description = "a short tag containing a-z0-9_ that describes the application used in resource naming"
    default =  "my_app"
}
variable "app_version" {
    description = "To highlight stale state"
    default =  "1"
}
variable "default_tags" {
  description = "Tags that may be handy to include across resources"
  type = map
  default     = {
      Name = "batch-executor"
    }
}

/* 
These Settings control the allocation of resource per job.  CPUs and memory ratios should be linked
to the instance class. 

For each class below, for every 2 vcpus use ram multipliers of:
R5:15gb, M5:7gb, C5:3gb

eg. a task which requires a lot of ram but not much cpu should use R class instances.  
If 30gb ram is needed, use 2 R5 units (4vcpu, 30gb). If instead that same task requires 30gb of ram 
and as much cpu as is available, use 10 C class units instead: 20vcpu and 30gb of ram.

Especially for large jobs the cost difference can be significant in the case above, 
C class is 3x more expensive so use R unless C is significantly faster. 
*/
variable "instance_types" {
    description = "How many vcpus per container"
    default = ["r5"] 
}
variable "task_vcpus" {
    description = "How many vcpus per container"
    default = 2 
}
variable "task_memory" {
    description = "How much ram is needed per container"
    default = 15000
}

/* 
Settings to control reference your dependencies your container and default deployable. 
*/
variable "container_image" {
  description = "The resource name of the container you will use to fetch and run"
  type = string
  default     = "xxx.dkr.ecr.region.amazonaws.com/yyy"
}
variable "ami_id" {
  description = "The id of the machine image to use for the batch executor nodes."
  type = string
  default     = "ami-xxx"
}
variable "test_script" {
  description = "The s3 key (wihtout bucket) of a test executable to use for fetch and run."
  type = string
  default     = "scripts/test/run.sh"
}

/* 
General infrastructure stuff that isn't very interesting but is very important.
*/
variable "region" {
  description = "The region where inf will be built."
  default = "eu-west-1"
}
variable "vpc_id" {
  description = "Existing VPC to use (specify this, if you don't want to create new VPC)"
  default     = "vpc-xxx"
}
variable "key_name" {
  description = "The name of your ssh key."
  default     = "_keyname_"
}
variable "sg_ids" {
  description = "Existing VPC Security Group to use (specify this, if you don't want to create new security groups"
  type = list
  default     = [
      "sg-xxx",
    ]
}
variable "subnets" {
  description = "Tags that may be handy to include across resources"
  type = list
  default     = [
      "subnet-xxx"
    ]
}