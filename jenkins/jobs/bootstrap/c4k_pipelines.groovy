// this bit is just plain Jenkins Groovy

import groovy.json.JsonSlurper

def secretsDirectory = new File("/secret/jenkins-secrets").exists() ? new File("/secret/jenkins-secrets") : new File("/var/jenkins_secrets");
def cloud = new File(secretsDirectory, "cloud").text.trim();

def cloudOpsForKubernetesRepoURL = new File(secretsDirectory, "cloudOpsForKubernetesRepoURL").text.trim();

def defaultGitServerHostKey = new File(secretsDirectory, "gitSSHHostKey").text.trim();

def defaultEpRepositoryUser = new File(secretsDirectory, "epRepositoryUser").text.trim();
def defaultEpRepositoryPassword = new File(secretsDirectory, "epRepositoryPassword").text.trim();

def defaultJdkDownloadUrl = new File(secretsDirectory, "oracleJdkDownloadUrl").text.trim();
def defaultJdkFolderName = new File(secretsDirectory, "jdkFolderName").text.trim();

def tomcatVersion = new File(secretsDirectory, "tomcatVersion").text.trim()

// CI pipeline secrets
def defaultAzureSubscriptionId = ""
def defaultAzureSpTenantId = ""
if(cloud.equals("azure")) {
  defaultAzureSubscriptionId = new File(secretsDirectory, "azureSubscriptionId").text.trim()
  defaultAzureSpTenantId = new File(secretsDirectory, "azureServicePrincipalTenantId").text.trim()
}
def pipelineSecretsDirectory = new File("/secret/jenkins-pipeline-secrets").exists() ? new File("/secret/jenkins-pipeline-secrets") : new File("/var/jenkins_pipeline_secrets");

// this map provides:
// 1. names for the test jobs (as the keys of the map)
// 2. settings in each job that differ between the jobs
def testJobsMap = [
  "nightly-ci-commerce-7.5.x": [
    "build-schedule": "H H(8-12) * * 4",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyIdMaster").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKeyMaster").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppIdMaster").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPasswordMaster").text.trim(),
      "resourceGroup": "k8smasterci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops-TEST/cloudops-for-kubernetes.git",
      "cloudOpsForKubernetesBranch": "master",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops-TEST/docker.git",
      "dockerBranch": "master",
      "domainName": "master75.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.5.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-commerce-7.6.x": [
    "build-schedule": "H H(8-12) * * 3,7",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyIdMaster").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKeyMaster").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppIdMaster").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPasswordMaster").text.trim(),
      "resourceGroup": "k8smasterci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops-TEST/cloudops-for-kubernetes.git",
      "cloudOpsForKubernetesBranch": "master",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops-TEST/docker.git",
      "dockerBranch": "master",
      "domainName": "master76.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.6.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-commerce-8.0.x": [
    "build-schedule": "H H(8-12) * * 2,6",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyIdMaster").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKeyMaster").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppIdMaster").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPasswordMaster").text.trim(),
      "resourceGroup": "k8smasterci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops-TEST/cloudops-for-kubernetes.git",
      "cloudOpsForKubernetesBranch": "master",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops-TEST/docker.git",
      "dockerBranch": "master",
      "domainName": "master80.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/8.0.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-commerce-master": [
    "build-schedule": "H H(8-12) * * 1,5",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyIdMaster").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKeyMaster").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppIdMaster").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPasswordMaster").text.trim(),
      "resourceGroup": "k8smasterci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops-TEST/cloudops-for-kubernetes.git",
      "cloudOpsForKubernetesBranch": "master",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops-TEST/docker.git",
      "dockerBranch": "master",
      "domainName": "mastermaster.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-cloudops-TEST/ep-commerce.git",
      "epCommerceBranch": "master",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex-staging/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine-staging/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators-staging/"
      ]
    ],
  "nightly-ci-k8s-2.1.x-commerce-7.5.x": [
    "build-schedule": "H H(8-12) * * 4",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyId20").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKey20").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppId20").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPassword20").text.trim(),
      "resourceGroup": "k8s20ci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops/cloud-ops-kubernetes.git",
      "cloudOpsForKubernetesBranch": "release/2.1.x",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops/docker.git",
      "dockerBranch": "release/3.6.x",
      "domainName": "2075.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.5.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-k8s-2.1.x-commerce-7.6.x": [
    "build-schedule": "H H(8-12) * * 3,7",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyId20").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKey20").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppId20").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPassword20").text.trim(),
      "resourceGroup": "k8s20ci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops/cloud-ops-kubernetes.git",
      "cloudOpsForKubernetesBranch": "release/2.1.x",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops/docker.git",
      "dockerBranch": "release/3.6.x",
      "domainName": "2076.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.6.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-k8s-2.1.x-commerce-8.0.x": [
    "build-schedule": "H H(8-12) * * 2,6",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyId20").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKey20").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppId20").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPassword20").text.trim(),
      "resourceGroup": "k8s20ci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops/cloud-ops-kubernetes.git",
      "cloudOpsForKubernetesBranch": "release/2.1.x",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops/docker.git",
      "dockerBranch": "release/3.6.x",
      "domainName": "2080.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/8.0.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-k8s-2.1.x-commerce-master": [
    "build-schedule": "H H(8-12) * * 1,5",
    "parameters": [
      "awsAccessKeyValue": new File(pipelineSecretsDirectory, "awsAccessKeyId20").text.trim(),
      "awsSecretKeyValue": new File(pipelineSecretsDirectory, "awsSecretAccessKey20").text.trim(),
      "azureSpAppIdValue": new File(pipelineSecretsDirectory, "azureServicePrincipalAppId20").text.trim(),
      "azureSpPasswordValue": new File(pipelineSecretsDirectory, "azureServicePrincipalPassword20").text.trim(),
      "resourceGroup": "k8s20ci",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops/cloud-ops-kubernetes.git",
      "cloudOpsForKubernetesBranch": "release/2.1.x",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops/docker.git",
      "dockerBranch": "release/3.6.x",
      "domainName": "20master.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-cloudops-TEST/ep-commerce.git",
      "epCommerceBranch": "master",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex-staging/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine-staging/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators-staging/"
      ]
    ],
  "on-demand-ci": [
    "build-schedule": "",
    "parameters": [
      "awsAccessKey": "",
      "awsSecretKey": "",
      "azureSubscription": "",
      "azureServicePrincipalApp": "",
      "azurePassword": "",
      "resourceGroup": "",
      "kubernetesClusterName": "hub",
      "cloudOpsForKubernetesURL": "git@code.elasticpath.com:ep-cloudops-TEST/cloudops-for-kubernetes.git",
      "cloudOpsForKubernetesBranch": "",
      "dockerURL": "git@code.elasticpath.com:ep-cloudops-TEST/docker.git",
      "dockerBranch": "master",
      "domainName": "",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.6.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ]
  ]

// for the syntax for the content of this file, see: https://jenkinsci.github.io/job-dsl-plugin/

nestedView('CloudOps Pipelines') {
    views {
        listView('All Pipelines') {
            jobs {
                regex(/nightly-.+|on-demand-ci/)
            }
            columns {
                status()
                weather()
                name()
                lastSuccess()
                lastFailure()
                lastDuration()
                buildButton()
            }
        }

        buildMonitorView('Commerce master Monitor') {
          description('Run Monday and Friday')
          jobs {
            regex('nightly-.+commerce-master')
          }
        }

        buildMonitorView('Commerce 8.0 Monitor') {
          description('Run Tuesday and Saturday')
          jobs {
            regex('nightly-.+commerce-8.0.x')
          }
        }

        buildMonitorView('Commerce 7.6 Monitor') {
          description('Run Wednesday and Sunday')
          jobs {
            regex('nightly-.+commerce-7.6.x')
          }
        }

        buildMonitorView('Commerce 7.5 Monitor') {
          description('Run Thursday')
          jobs {
            regex('nightly-.+commerce-7.5.x')
          }
        }
    }
}

// since our test jobs share a lot of common configuration, the common config is included below while
// the different config is stored in testJobsMap

if (cloud == "aws") {

  for(testJobsMapEntry in testJobsMap) {
    def testJobName = testJobsMapEntry.key
    def testJobConfigMap = testJobsMapEntry.value
    def testJobParametersMap = testJobConfigMap.get("parameters")

    pipelineJob("${testJobName}") {
      description("For more information about the parameters, see the docker-compose.yml file in the root of the CloudOps for Kubernetes Git repository.")
      definition {
        cpsScm {
          scm {
            git {
              remote {
                url('${cloudOpsForKubernetesRepoURL}')
                credentials('gitCredentialId')
              }
              extensions {
                cloneOptions {
                  shallow(true)
                  depth(10)
                }
                relativeTargetDirectory('cloudops-for-kubernetes')
              }
              branch('${cloudOpsForKubernetesBranch}')
            }
          }
          lightweight(false)
          scriptPath('cloudops-for-kubernetes/jenkins/jobs/cloudops-for-kubernetes-ci/Jenkinsfile')
        }
      }
      parameters {
        stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which to deploy the pod which will bootstrap CloudOps for Kubernetes')
        booleanParam('cleanupResourceGroup', true, 'Clean up the resources created by this job')
        booleanParam('runCortexSystemTests', true, 'Run the Cortex system tests on the deployed ep-stacks')
        stringParam('awsAccessKeyId', testJobParametersMap.get("awsAccessKeyValue"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        simpleParam('hudson.model.PasswordParameterDefinition', 'awsSecretAccessKey', testJobParametersMap.get("awsSecretKeyValue"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('domainName', testJobParametersMap.get("domainName"), 'A subdomain of the domain name in zoneForNSRecord. For parameter details, see the CloudOps for Kubernetes docker-compose file.')
        stringParam('zoneForNSRecord', "${cloud}.epcloudops.com", 'The name of the DNS Zone where name server records will be created to point to the DNS Zone created by the bootstrap process.')
        stringParam('kubernetesClusterName', testJobParametersMap.get("kubernetesClusterName"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('region', 'us-west-2', 'AWS region to use.')
        stringParam('eksInstanceType', 'm5a.xlarge', 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('eksNodeCount', '1', 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('jenkinsIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Jenkins. \nex. "1.2.3.4/32,2.3.4.5/32"')
        stringParam('nexusIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Nexus. \nex. "1.2.3.4/32,2.3.4.5/32"')
        stringParam('cloudOpsForKubernetesBranch', testJobParametersMap.get("cloudOpsForKubernetesBranch"), 'CloudOps for Kubernetes branch to use')
        stringParam('cloudOpsForKubernetesRepoURL',  testJobParametersMap.get("cloudOpsForKubernetesURL"), 'CloudOps for Kubernetes Git repository URL')
        stringParam('epCommerceBranch', testJobParametersMap.get("epCommerceBranch"), 'EP Commerce branch to use')
        stringParam('epCommerceRepoURL', testJobParametersMap.get("epCommerceRepoURL"), 'EP Commerce Git repository URL')
        stringParam('dockerBranch', testJobParametersMap.get("dockerBranch"), 'EP Docker branch to use')
        stringParam('dockerRepoURL', testJobParametersMap.get("dockerURL"), 'EP Docker Git repository URL')
        credentialsParam('gitReposPrivateKey') {
          type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
          required()
          defaultValue('gitCredentialId')
          description('Private SSH key authorized to clone from repositories specified by cloudOpsForKubernetesRepoURL, epCommerceRepoURL and dockerRepoURL.')
        }
        stringParam('gitSSHHostKey', defaultGitServerHostKey, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epRepositoryUser', defaultEpRepositoryUser, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        simpleParam('hudson.model.PasswordParameterDefinition', 'epRepositoryPassword', defaultEpRepositoryPassword, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epCortexMavenRepoUrl', testJobParametersMap.get("epCortexMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epCommerceEngineMavenRepoUrl', testJobParametersMap.get("epCommerceEngineMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epAcceleratorsMavenRepoUrl', testJobParametersMap.get("epAcceleratorsMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('oracleJdkDownloadUrl', defaultJdkDownloadUrl, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('jdkFolderName', defaultJdkFolderName, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('tomcatVersion', tomcatVersion, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
      }
      triggers {
          cron(testJobConfigMap.get("build-schedule"))
      }
    }
  }

} else if (cloud == "azure") {

  for(testJobsMapEntry in testJobsMap) {
    def testJobName = testJobsMapEntry.key
    def testJobConfigMap = testJobsMapEntry.value
    def testJobParametersMap = testJobConfigMap.get("parameters")

    pipelineJob("${testJobName}") {
      description("For more information about the parameters, see the docker-compose.yml file in the root of the CloudOps for Kubernetes Git repository.")
      definition {
        cpsScm {
          scm {
            git {
              remote {
                url('${cloudOpsForKubernetesRepoURL}')
                credentials('gitCredentialId')
              }
              extensions {
                cloneOptions {
                  shallow(true)
                  depth(10)
                }
                relativeTargetDirectory('cloudops-for-kubernetes')
              }
              branch('${cloudOpsForKubernetesBranch}')
            }
          }
          lightweight(false)
          scriptPath('cloudops-for-kubernetes/jenkins/jobs/cloudops-for-kubernetes-ci/Jenkinsfile')
        }
      }
      parameters {
        stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which to deploy the pod which will bootstrap CloudOps for Kubernetes')
        booleanParam('cleanupResourceGroup', true, 'Clean up the resources created by this job')
        booleanParam('runCortexSystemTests', true, 'Run Cortex system tests on the deployed Commerce stacks')
        stringParam('resourceGroup', testJobParametersMap.get("resourceGroup"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('azureServicePrincipalTenantId', defaultAzureSpTenantId, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('azureSubscriptionId', defaultAzureSubscriptionId, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('azureServicePrincipalAppId', testJobParametersMap.get("azureSpAppIdValue"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        simpleParam('hudson.model.PasswordParameterDefinition', 'azureServicePrincipalPassword', testJobParametersMap.get("azureSpPasswordValue"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('domainName', testJobParametersMap.get("domainName"), 'A subdomain of the domain name in zoneForNSRecord')
        stringParam('zoneForNSRecord', "${cloud}.epcloudops.com", 'The name of the DNS Zone where name server records will be created to point to the DNS Zone created by the bootstrap process.')
        stringParam('resourceGroupForParentZone', 'ImmortalResourceGroup', 'The Resource Group that zoneForNSRecord is a part of.')
        stringParam('kubernetesClusterName', testJobParametersMap.get("kubernetesClusterName"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('location', 'westus2', 'Azure location to use.')
        stringParam('aksNodeVMSize', 'Standard_B4ms', 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('aksNodeCount', '1', 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('jenkinsIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Jenkins. \nex. "1.2.3.4/32,2.3.4.5/32"')
        stringParam('nexusIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Nexus. \nex. "1.2.3.4/32,2.3.4.5/32"')
        stringParam('cloudOpsForKubernetesBranch', testJobParametersMap.get("cloudOpsForKubernetesBranch"), 'CloudOps for Kubernetes branch to use')
        stringParam('cloudOpsForKubernetesRepoURL',  testJobParametersMap.get("cloudOpsForKubernetesURL"), 'CloudOps for Kubernetes Git repository URL')
        stringParam('epCommerceBranch', testJobParametersMap.get("epCommerceBranch"), 'EP Commerce branch to use')
        stringParam('epCommerceRepoURL', testJobParametersMap.get("epCommerceRepoURL"), 'EP Commerce Git repository URL')
        stringParam('dockerBranch', testJobParametersMap.get("dockerBranch"), 'EP Docker branch to use')
        stringParam('dockerRepoURL', testJobParametersMap.get("dockerURL"), 'EP Docker Git repository URL')
        credentialsParam('gitReposPrivateKey') {
          type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
          required()
          defaultValue('gitCredentialId')
          description('Private SSH key authorized to clone from repositories specified by cloudOpsForKubernetesRepoURL, epCommerceRepoURL and dockerRepoURL.')
        }
        stringParam('gitSSHHostKey', defaultGitServerHostKey, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epRepositoryUser', defaultEpRepositoryUser, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        simpleParam('hudson.model.PasswordParameterDefinition', 'epRepositoryPassword', defaultEpRepositoryPassword, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epCortexMavenRepoUrl', testJobParametersMap.get("epCortexMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epCommerceEngineMavenRepoUrl', testJobParametersMap.get("epCommerceEngineMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('epAcceleratorsMavenRepoUrl', testJobParametersMap.get("epAcceleratorsMavenRepoUrl"), 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('oracleJdkDownloadUrl', defaultJdkDownloadUrl, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('jdkFolderName', defaultJdkFolderName, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
        stringParam('tomcatVersion', tomcatVersion, 'For more information about parameters see the CloudOps for Kubernetes Docker Compose file')
      }
      triggers {
          cron(testJobConfigMap.get("build-schedule"))
      }
    }
  }

}
