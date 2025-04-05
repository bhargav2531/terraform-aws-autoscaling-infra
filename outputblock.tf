output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.autoscale_vpc.id
}

output "subnet_1_id" {
  description = "The ID of the first subnet"
  value       = aws_subnet.autoscale_subnet_az1.id
}

output "subnet_2_id" {
  description = "The ID of the second subnet"
  value       = aws_subnet.autoscale_subnet_az2.id
}

output "security_group_id" {
  description = "The ID of the Security Group"
  value       = aws_security_group.autoscale_sg.id
}

output "instance_id" {
  description = "The ID of the EC2 Instance"
  value       = aws_instance.autoscale_instance.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.autoscale_asg.name
}

output "load_balancer_dns" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.autoscale_lb.dns_name
}

output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = aws_lb_target_group.autoscale_target_group.arn
}

output "launch_template_id" {
  description = "The ID of the Launch Template"
  value       = aws_launch_template.autoscale_launch_template.id
}

