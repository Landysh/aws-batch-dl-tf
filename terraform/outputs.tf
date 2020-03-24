output "job_queue_arn" {
  value = aws_batch_job_queue.primary.arn
}
output "job_definition_arn" {
  value = aws_batch_job_definition.primary.arn
}
output "test_scipt_url" {
    value = local.test_script_url
}
output "region" {
    value = local.region
}
output "s3_bucket_name" {
    value = aws_s3_bucket.results.bucket
}