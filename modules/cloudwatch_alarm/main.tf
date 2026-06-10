resource "aws_cloudwatch_metric_alarm" "cpu_high" {

  alarm_name = var.alarm_name

  comparison_operator = "GreaterThanThreshold"

  evaluation_periods = 2

  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"

  period = 60

  statistic = "Average"

  threshold = 70

  alarm_description = "CPU High"

  alarm_actions = [
    var.topic_arn
  ]

  dimensions = {

    AutoScalingGroupName = var.asg_name
  }
}
