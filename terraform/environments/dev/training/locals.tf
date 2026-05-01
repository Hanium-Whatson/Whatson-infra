locals {
  raw_prefix        = "raw"
  processed_prefix  = "processed"
  dataset_prefix    = "dataset"
  artifact_prefix   = "model-artifact"
  checkpoint_prefix = "${local.artifact_prefix}/checkpoints"
}
