# Module6:Deployment Management

![0309](./images/sap-student-guide-0309.png)

![0310](./images/sap-student-guide-0310.png)

![0311](./images/sap-student-guide-0311.png)

AWS has several services that can be used for different aspects of deployment.

This slide and the subsequent slides place those services into different layers to help you understand which services are typically used for which purpose.

**AWS Elastic Beanstal**

Elastic Beanstalk appears in all four deployment categories. Why wouldn’t you simply use it for everything?

Elastic Beanstalk has strong requirements for the way an application is architected. It works best when you use a two-tier or three-tier application. The service offers a choice between web or worker tier, RDS database tier, and possibly a load balancer. A web tier is typically behind a load balancer. A worker tier uses an SQS queue. Elastic Beanstalk deploys only to Amazon EC2 instances, not to systems outside AWS.

Elastic Beanstalk can be extended to include other AWS services. However, it won’t actively manage those other services.

If your application fits into the Beanstalk model, it’s a great starting point.

![0312](./images/sap-student-guide-0312.png)

**AWS OpsWorks**

OpsWorks has a DevOps focus. It allows ongoing management of your environment, and provides more control than Elastic Beanstalk. For example, you can do rolling upgrades of the EC2 instance operating systems or install custom software via Chef recipes. OpsWorks can manage systems in Amazon EC2 and systems that are external to AWS. It does not follow the concept of multiple application versions.

**AWS CloudFormation**

AWS CloudFormation deploys environments based on a template. CloudFormation doesn’t have the ongoing configuration management capabilities of OpsWorks. Most or all AWS services are supported for deployment via CloudFormation.

![0313](./images/sap-student-guide-0313.png)

**AWS CodeCommit**

CodeCommit is a managed Git code repository; it can store multiple versions of code and also deployment artifacts. CodeCommit doesn’t compile or deploy code. It relies on other services or systems to do this. Contrast this with Elastic Beanstalk, which can also keep and deploy multiple application versions. However, Elastic Beanstalk stores and maintains only deployment artifacts, not source code.

**AWS CodePipeline**

CodePipeline performs automated software testing before release. It doesn’t deploy code.

![0314](./images/sap-student-guide-0314.png)

**AWS CodeDeploy**

CodeDeploy handles deployment of application artifacts to target systems. It can deploy to both EC2 instances and external systems. CodeDeploy can store multiple application versions and has powerful, customizable logic to control deployment behavior.

![0315](./images/sap-student-guide-0315.png)

**Amazon Elastic Container Service (Amazon ECS)**

Amazon ECS deploys Docker containers and provides container management and scheduling.

**AWS Lambda**

Lambda uses an event-driven or reactive-programming approach. This is useful for short-term (up to five minutes) processing requirements for data, such as processing objects in Amazon Simple Storage Service (S3) or updating Amazon DynamoDB. AWS manages concurrency and scaling of your Lambda functions. AWS Lambda is not useful for long-running jobs.

For more information, see:

- Overview of Deployment Options on AWS: <https://d0.awsstatic.com/whitepapers/overview-of-deployment-options-on-aws.pdf>
- Managing Your AWS Infrastructure at Scale: <https://d0.awsstatic.com/whitepapers/managing-your-aws-infrastructure-at-scale.pdf>

![0316](./images/sap-student-guide-0316.png)

The following slides use the Lifecycle Events from AWS OpsWorks to illustrate how
you can use AWS services to manage an application lifecycle. Lifecycle events are:

- Set up
- Configure
- Deploy
- Undeploy
- Shut down

**Setup/Configure – AWS CloudFormation**

The unit of AWS CloudFormation deployment is a stack, which is instantiated from an AWS CloudFormation template.

To configure instances, use CloudFormation::Init, which is a set of directives to configure an EC2 instance or an Auto Scaling group. The directives are grouped into users, groups, files, sources, services, and commands. CloudFormation::Init can contain multiple groups of directives and you can choose one when creating a stack.

Configuration actions such as installing software on an EC2 instance can take time to complete. When using CloudFormation::Init to configure EC2 instances, the instances can use the CreationPolicy property or a CloudFormation WaitCondition resource to signal that configuration is complete.

CreationPolicy is a property of an instance or Auto Scaling group. This defines a time limit to wait for the instance(s) to complete configuration. If a CreationPolicy is used as a property of an Auto Scaling group, you can specify a percentage or count of instances. For example, you may need 50% of the instances to be online to consider creation complete.

Similarly to CreationPolicy, a WaitCondition is a separate resource that allows a delay. A WaitCondition is a separate CloudFormation resource, not a property of an instance or Auto Scaling group. Multiple instances can depend on one WaitCondition, such as a database and a cache, both of which need to be configured before CloudFormation creates application servers.

The instances send a signal to AWS CloudFormation using the cfn-signal tool, which AWS provides for most operating systems.

For a related video from the 2015 re:Invent on CloudFormation best practices, see: <https://www.youtube.com/watch?v=fVMlxJJNmyA>

![0318](./images/sap-student-guide-0318.png)

UserData is an alternative to AWS::CloudFormation::Init. With UserData, you are just executing raw shell code. The biggest difference between AWS::CloudFormation::Init and UserData is error handling. With UserData, you use another tool called cfn-signal to notify AWS CloudFormation that the UserData script has successfully executed—or, if there was an error, to capture that error and then notify AWS CloudFormation that a resource was not created successfully. With CloudFormation::Init, that function is built in inherently within the DSL.

Stack updates help when you have a stack that is running (e.g., resources were created with an AWS CloudFormation template) and you need to make some change (e.g., change to security groups, user policies, etc.). You can document those changes in the same AWS CloudFormation template. First do an update-stack operation and pass the new template. AWS receives that new template via the API call, looks at the current stack and the properties that are applied to those resources, and compares them to the new AWS CloudFormation template, identifying the differences. The differences are what end up being executed on. There is also another feature that blends into this process: Change Sets. When you do an update-stack operation, you are identifying what the potential changes are, but you do not specify when those changes should be applied. By using Change Set, you can identify what resources are impacted and then specify the timing of when those changes are executed (e.g., some changes might require a downtime window, which you would want to do during an off-peak time).

![0320](./images/sap-student-guide-0320.png)

delete-stack operation is the opposite of a create stack operation. In a create-stack operation, AWS goes through the AWS CloudFormation template submitted and executes those resources in the order you defined them in the template. In a delete-stack, the opposite occurs. AWS systematically removes those resources in a top-down approach. For instance, EC2 instances might be removed first, followed by the networking construct (e.g. VPC), and then the users and groups. That way, all resources are cleaned up and there are no dangling dependencies persisting in your account after you no longer need this application.

In regards to a DeletionPolicy: sometimes when you are deprovisioning resources, you don’t want to pay for the resource itself, but you still need some of the data contained in that service. For example, with an RDS database, you may no longer need the service, but don’t want to lose the data associated with that database. By applying a DeletionPolicy onto that resource in the AWS CloudFormation notation, you can indicate to create a snapshot of your data before deleting the resource. Snapshot storage is much cheaper than having a service like Amazon RDS running 24 hours, 7 days a week, sitting idle just to store data.

![0321](./images/sap-student-guide-0321.png)

First, author a template. Then perform a create-stack operation to generate all of the resources defined with that template. All the property values you define in that AWS CloudFormation notation are applied to those resources. Then you can do an update-stack operation in order to apply changes and make modifications throughout the lifecycle of your app. Finally, run a delete-stack operation, which is the inverse of create-stack—removing all those resources in the correct order.

![0322](./images/sap-student-guide-0322.png)

**Deploy – AWS CodeDeploy**

AWS CodeDeploy deploys code to a set of instances (within EC2, outside AWS, or a combination of both). It doesn’t set up the EC2 instances, though. AWS CloudFormation or other services can be used for that.

An AWS CodeDeploy application has multiple revisions (called versions). An application has deployment configurations and deployment groups. The application binaries are stored in Amazon S3 or in GitHub.

AWS CodeDeploy deploys the application revision to EC2 instances identified by tag or by membership in an Auto Scaling group. A deployment configuration can be used to target a portion of instances. For example, AWS CodeDeploy can deploy to a percentage of the fleet at a time.

A deployment configuration can contain custom deployment rules and logic for pre-and post-tasks. For example, a pre-deployment task may stop a service/daemon and remove the instance from an Elastic Load Balancing load balancer before updating the code. A post-deployment task may restart the service and then re-add the instance to the load balancer.

AWS CodeDeploy uses appspec.yml (which is usually checked in with the application source code) to orchestrate the deployment activities. Appspec.yml has lifecycle hooks, that AWS CodeDeploy triggers scripts on.

For more information on AWS CodeDeploy deployments, see: <http://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps.html>

For more information on AWS CodeDeploy Lifecycle Hooks, see: <http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref-hooks.html>

![0324](./images/sap-student-guide-0324.png)

**Undeploy/Shut down – AWS CodeDeploy**

AWS CodeDeploy can remove applications by using customized pre-or post-deployment scripts.

AWS CodeDeploy cannot remove the underlying infrastructure (EC2 instances). Typically, another service such as AWS CloudFormation is used to remove the infrastructure components.

![0325](./images/sap-student-guide-0325.png)

**AWS CodeDeploy Tips**

1. The AWS CodeDeploy agent is open source. It has been tested on Amazon Linux, RHEL, Ubuntu server, and Windows.
2. The AWS CodeDeploy agent supports installation on on-premises systems, as well as EC2 instances.
3. Three parameters are required for a deployment:
   1. i. Revision – Specifies what to deploy
   2. ii. Deployment group – Specifies where to deploy
   3. iii. Deployment configuration – An optional parameter that specifies how to deploy
4. You can associate an Auto Scaling group with a deployment group to make sure that newly launched instances always get the latest version of your application. Every time a new Amazon EC2 instance is launched for that Auto Scaling group, it is first put in a Pending state, and then a deployment of the last successful revision for that deployment group is triggered on that Amazon EC2 instance. If the deployment completes successfully, the state of the Amazon EC2 instance is changed to InService. If that deployment fails, the Amazon EC2 instance is terminated, a new Amazon EC2 instance is launched in Pending state, and a deployment is triggered for the newly launched EC2 instance.
5. To roll back an application to a previous revision, you just need to deploy that revision.
6. CodeDeploy keeps track of the files that were copied for the current revision and removes them before starting a new deployment.
7. CodeDeploy supports resource-level permissions: <http://docs.aws.amazon.com/IAM/latest/UserGuide/access_permissions.html>. For each AWS CodeDeploy resource, you can specify which user has access to which actions. For example, you can create an IAM policy to allow a user to deploy a particular application, but only list revisions for other applications.

![0327](./images/sap-student-guide-0327.png)

**Set up/Configure – AWS Elastic Beanstalk**

An Elastic Beanstalk application contains one or more environments to deploy an application onto. Each environment can be a single EC2 instance or a load-balanced Auto Scaling group. A single application can have multiple Elastic Beanstalk environments.

You can configure and customize an Elastic Beanstalk environment using .ebextensions, which is a folder in the root of the application package, and contains files in a YAML format. The files specify users, groups, services, files, sources, and commands. This is much the same as CloudFormation::Init property.

For directives in .ebextensions, you can specify leader_only, in which case:

- Elastic Beanstalk elects a leader for the environment and
- Elastic Beanstalk executes leader_only directives against only that instance.

For example, a new version of your application requires a schema update to the database. You want that schema update to happen only once. To do this, put the schema update command in the .ebextensions file and specify leader_only for that directive

**Resources:**

- For a video from the 2014 re:Invent entitled “Deploy, Manage, Scale Apps w/ AWS OpsWorks and Elastic Beanstalk, see: <https://www.youtube.com/watch?v=KZoTh3hZTyo>
- For information on AWS Elastic Beanstalk Environment Configuration, see: <http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers.html#customize-containers-format>
- For information on customizing software on Windows Servers, see: <http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-windows-ec2.html>
- For information on customizing software on Linux Servers, see: <http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-ec2.html>

![0329](./images/sap-student-guide-0329.png)

**Deploy – Elastic Beanstalk**

An Elastic Beanstalk application can contain multiple application versions. An application version is deployed to an environment.

You can upload a new version of your application to Elastic Beanstalk, specifying a version label. After upload, you can deploy the new version to an Elastic Beanstalk environment. A deployment can target a whole environment or perform a rolling update to a percentage of instances in the environment.

The “deployment with zero downtime” option deploys a new application version to a second environment, and then swaps the DNS CNAME between the two environments.

For more information on deploying applications to AWS Elastic Beanstalk environments, see: <http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deploy-existing-version.html>

![0330](./images/sap-student-guide-0330.png)

**Undeploy/Shutdown – Elastic Beanstalk**

An environment can be removed from an Elastic Beanstalk application. An application version running on that environment will be stopped as part of the removal of the environment.

![0331](./images/sap-student-guide-0331.png)
![0332](./images/sap-student-guide-0332.png)
![0333](./images/sap-student-guide-0333.png)
![0334](./images/sap-student-guide-0334.png)
![0335](./images/sap-student-guide-0335.png)
![0336](./images/sap-student-guide-0336.png)
![0337](./images/sap-student-guide-0337.png)
![0338](./images/sap-student-guide-0338.png)
![0339](./images/sap-student-guide-0339.png)

![0340](./images/sap-student-guide-0340.png)
![0341](./images/sap-student-guide-0341.png)
![0342](./images/sap-student-guide-0342.png)
![0343](./images/sap-student-guide-0343.png)
![0344](./images/sap-student-guide-0344.png)
![0345](./images/sap-student-guide-0345.png)
![0346](./images/sap-student-guide-0346.png)
![0347](./images/sap-student-guide-0347.png)
![0348](./images/sap-student-guide-0348.png)
![0349](./images/sap-student-guide-0349.png)

![0350](./images/sap-student-guide-0350.png)
![0351](./images/sap-student-guide-0351.png)
![0352](./images/sap-student-guide-0352.png)
![0353](./images/sap-student-guide-0353.png)
![0354](./images/sap-student-guide-0354.png)
![0355](./images/sap-student-guide-0355.png)
![0356](./images/sap-student-guide-0356.png)
![0357](./images/sap-student-guide-0357.png)
![0358](./images/sap-student-guide-0358.png)
![0359](./images/sap-student-guide-0359.png)

![0360](./images/sap-student-guide-0360.png)
![0361](./images/sap-student-guide-0361.png)
![0362](./images/sap-student-guide-0362.png)
![0363](./images/sap-student-guide-0363.png)
![0364](./images/sap-student-guide-0364.png)
![0365](./images/sap-student-guide-0365.png)
![0366](./images/sap-student-guide-0366.png)
![0367](./images/sap-student-guide-0367.png)
![0368](./images/sap-student-guide-0368.png)
![0369](./images/sap-student-guide-0369.png)

![0370](./images/sap-student-guide-0370.png)
![0371](./images/sap-student-guide-0371.png)
![0372](./images/sap-student-guide-0372.png)
![0373](./images/sap-student-guide-0373.png)
![0374](./images/sap-student-guide-0374.png)
![0375](./images/sap-student-guide-0375.png)
![0376](./images/sap-student-guide-0376.png)
![0377](./images/sap-student-guide-0377.png)
![0378](./images/sap-student-guide-0378.png)
![0379](./images/sap-student-guide-0379.png)

![0380](./images/sap-student-guide-0380.png)
![0381](./images/sap-student-guide-0381.png)
![0382](./images/sap-student-guide-0382.png)
![0383](./images/sap-student-guide-0383.png)
![0384](./images/sap-student-guide-0384.png)
![0385](./images/sap-student-guide-0385.png)
![0386](./images/sap-student-guide-0386.png)
![0387](./images/sap-student-guide-0387.png)
![0388](./images/sap-student-guide-0388.png)
![0389](./images/sap-student-guide-0389.png)

![0390](./images/sap-student-guide-0390.png)
![0391](./images/sap-student-guide-0391.png)
![0392](./images/sap-student-guide-0392.png)
![0393](./images/sap-student-guide-0393.png)
![0394](./images/sap-student-guide-0394.png)
![0395](./images/sap-student-guide-0395.png)
![0396](./images/sap-student-guide-0396.png)
![0397](./images/sap-student-guide-0397.png)
![0398](./images/sap-student-guide-0398.png)
![0399](./images/sap-student-guide-0399.png)