# ayo_ngnix

Overview
This document outlines the steps to set up an AWS infrastructure using Terraform, deploy an EC2 instance in a private subnet, and configure a load balancer to provide public access to a Dockerized NGINX server.

Prerequisites
AWS Account
Terraform installed on your local machine
SSH key pair for accessing EC2 instances
Docker installed on your local machine (for building the NGINX Docker image)



Step-by-Step Setup
Terraform Configuration

Create the following Terraform configuration files in your working directory:
main.tf
variables.tf
userdata.tpl
Dockerfile
index.html

Optional for template/automation depending on Os running this
Windows or Linux ssh configuration

Steps to Execute the Terraform Code and Launch the Application

1) Initialize Terraform
Open a terminal in the directory containing your Terraform configuration files and run:
$terraform init
Validate the Configuration
Validate your configuration files to ensure there are no syntax errors:
$terraform validate
Apply the Configuration
Apply the Terraform configuration to create the resources in AWS:
$terraform apply
Review the changes and type yes when prompted to confirm.





