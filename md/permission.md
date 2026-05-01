1) Terraform 실행 주체(사람/CI Role)에 필요한 권한
아래 서비스 권한을 요청하면 됩니다.

ec2:* 중 최소:
VPC/서브넷/라우팅/NAT/IGW/EIP/SG/인스턴스 관련
예: CreateVpc, DeleteVpc, CreateSubnet, CreateRouteTable, CreateNatGateway, AllocateAddress, CreateSecurityGroup, RunInstances, TerminateInstances, Describe*
s3:* 중 최소:
버킷/버전닝/암호화/PublicAccessBlock/오브젝트(prefix placeholder) 관리
예: CreateBucket, DeleteBucket, PutBucketVersioning, PutEncryptionConfiguration, PutBucketPublicAccessBlock, PutObject, DeleteObject, ListBucket, GetBucket*
lambda:* 중 최소:
함수 생성/수정/삭제 + invoke config + permission
예: CreateFunction, UpdateFunctionCode, UpdateFunctionConfiguration, DeleteFunction, AddPermission, RemovePermission, PutFunctionEventInvokeConfig, GetFunction
iam:* 중 최소:
Role/InstanceProfile/InlinePolicy/ManagedPolicyAttachment
예: CreateRole, DeleteRole, PutRolePolicy, DeleteRolePolicy, AttachRolePolicy, DetachRolePolicy, CreateInstanceProfile, AddRoleToInstanceProfile, PassRole, GetRole
events:*(EventBridge) 중 최소:
스케줄 룰/타깃
예: PutRule, DeleteRule, PutTargets, RemoveTargets, DescribeRule, ListTargetsByRule
sqs:* 중 최소:
DLQ 생성/설정/삭제
예: CreateQueue, DeleteQueue, SetQueueAttributes, GetQueueAttributes
elasticache:* 중 최소:
Redis subnet group / replication group
예: CreateReplicationGroup, DeleteReplicationGroup, CreateCacheSubnetGroup, DeleteCacheSubnetGroup, Describe*
logs:* 중 최소:
로그 그룹 생성/삭제
예: CreateLogGroup, DeleteLogGroup, PutRetentionPolicy, DescribeLogGroups
추가로 Terraform 조회 동작 때문에 각 서비스의 List*, Get*, Describe*는 넉넉히 포함하는 것이 안전합니다.

2) 코드에서 확인한 실제 AWS 리소스 타입
현재 terraform/modules 기준:

EC2/VPC: aws_vpc, aws_subnet, aws_route_table, aws_route_table_association, aws_internet_gateway, aws_nat_gateway, aws_eip, aws_security_group, aws_security_group_rule, aws_instance
S3: aws_s3_bucket, aws_s3_bucket_versioning, aws_s3_bucket_server_side_encryption_configuration, aws_s3_bucket_public_access_block, aws_s3_object
Lambda: aws_lambda_function, aws_lambda_function_event_invoke_config, aws_lambda_permission
IAM: aws_iam_role, aws_iam_role_policy, aws_iam_role_policy_attachment, aws_iam_instance_profile
EventBridge: aws_cloudwatch_event_rule, aws_cloudwatch_event_target
SQS: aws_sqs_queue
ElastiCache: aws_elasticache_subnet_group, aws_elasticache_replication_group
CloudWatch Logs: aws_cloudwatch_log_group