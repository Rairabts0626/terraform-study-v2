## Technologies

### Infrastructure as Code

* Terraform

### AWS Services

* VPC
* Subnet (Public / Private)
* Internet Gateway
* NAT Gateway
* Route Table
* Security Group
* Application Load Balancer (ALB)
* Auto Scaling Group (ASG)
* Launch Template
* Amazon RDS (MySQL)
* Route53
* ACM
* SNS
* CloudWatch

### Terraform Backend

* Amazon S3 (Terraform State Management)
* Amazon DynamoDB (State Locking)


## Key Points

* Terraform BackendとしてS3を利用し、Stateファイルをリモート管理
* DynamoDBによるState Lockを実装し、同時実行による競合を防止
* WordPressをPrivate Subnetで運用
* ALB + Auto Scaling Groupによる高可用性構成
* Route53 + ACMによるHTTPS化
* Terraform変数を利用したNAT GatewayのON/OFF制御によるコスト最適化

