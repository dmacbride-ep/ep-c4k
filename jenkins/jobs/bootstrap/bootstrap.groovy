// this bit is just plain Jenkins Groovy

import groovy.json.JsonSlurper

def secretsDirectory = new File("/secret/jenkins-secrets").exists() ? new File("/secret/jenkins-secrets") : new File("/var/jenkins_secrets");
def cloud = new File(secretsDirectory, "cloud").text.trim();

def cloudOpsForKubernetesRepoURL = new File(secretsDirectory, "cloudOpsForKubernetesRepoURL").text.trim();
def cloudOpsForKubernetesDefaultBranch = new File(secretsDirectory, "cloudOpsForKubernetesDefaultBranch").text.trim();
def cloudOpsForKubernetesCredentialId = "gitCredentialId";

def epCommerceRepoURL = new File(secretsDirectory, "epCommerceRepoURL").text.trim();
def epCommerceDefaultBranch = new File(secretsDirectory, "epCommerceDefaultBranch").text.trim();
def epCommerceCredentialId = "gitCredentialId";

def dockerRepoURL = new File(secretsDirectory, "dockerRepoURL").text.trim();
def dockerDefaultBranch = new File(secretsDirectory, "dockerDefaultBranch").text.trim();
def dockerCredentialId = "gitCredentialId";
def tomcatVersion = new File(secretsDirectory, "tomcatVersion").text.trim();

def bootstrapExtrasPropertiesFile = new File(secretsDirectory, "bootstrapExtrasProperties");

def defaultGitServerHostKey = new File(secretsDirectory, "gitSSHHostKey").text.trim();

def defaultEpEnvironment = "ci";

def defaultAzureSubscriptionId = ""
def defaultAzureSpTenantId = ""
def defaultAzureSpAppId = ""
def defaultAzureSpPassword = ""
if(cloud.equals("azure")) {
  defaultAzureSubscriptionId = new File(secretsDirectory, "azureSubscriptionId").text.trim();
  defaultAzureSpTenantId = new File(secretsDirectory, "azureServicePrincipalTenantId").text.trim();
  defaultAzureSpAppId = new File(secretsDirectory, "azureServicePrincipalAppId").text.trim();
  defaultAzureSpPassword = new File(secretsDirectory, "azureServicePrincipalPassword").text.trim();
}

def defaultEpRepositoryUser = new File(secretsDirectory, "epRepositoryUser").text.trim();
def defaultEpRepositoryPassword = new File(secretsDirectory, "epRepositoryPassword").text.trim();
def defaultEpCortexMavenRepoUrl = new File(secretsDirectory, "epCortexMavenRepoUrl").text.trim();
def defaultEpCommerceEngineMavenRepoUrl = new File(secretsDirectory, "epCommerceEngineMavenRepoUrl").text.trim();
def defaultEpAcceleratorsMavenRepoUrl = new File(secretsDirectory, "epAcceleratorsMavenRepoUrl").text.trim();

def defaultJdkDownloadUrl = new File(secretsDirectory, "oracleJdkDownloadUrl").text.trim();
def defaultJdkFolderName = new File(secretsDirectory, "jdkFolderName").text.trim();

def kubernetesClusterName = new File(secretsDirectory, "kubernetesClusterName").text.trim();
def rootDomainName = new File(secretsDirectory, "domainName").text.trim();

def defaultAmReleasePackageUrl = new File(secretsDirectory, "defaultAmReleasePackageUrl").text.trim();

// this map provides:
// 1. names for the test jobs (as the keys of the map)
// 2. settings in each job that differ between the jobs
def testJobsMap = [
  "nightly-ci-commerce-7.5.x": [
    "build-schedule": "H H(8-12) * * *",
    "parameters": [
      "resourceGroup": "k8sci75",
      "kubernetesClusterName": "hub",
      "domainName": "k8sci75.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.5.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-commerce-7.6.x": [
    "build-schedule": "H H(8-12) * * *",
    "parameters": [
      "resourceGroup": "k8sci76",
      "kubernetesClusterName": "hub",
      "domainName": "k8sci76.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.6.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ],
  "nightly-ci-commerce-master": [
    "build-schedule": "H H(8-12) * * *",
    "parameters": [
      "resourceGroup": "k8scimaster",
      "kubernetesClusterName": "hub",
      "domainName": "k8scimaster.${cloud}.epcloudops.com",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-cloudops-TEST/ep-commerce-pebbles.git",
      "epCommerceBranch": "master",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex-staging/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine-staging/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators-staging/"
      ]
    ],
  "on-demand-ci": [
    "build-schedule": "",
    "parameters": [
      "resourceGroup": "",
      "kubernetesClusterName": "hub",
      "domainName": "",
      "epCommerceRepoURL": "git@code.elasticpath.com:ep-commerce/ep-commerce.git",
      "epCommerceBranch": "release/7.5.x",
      "epCortexMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/cortex/",
      "epCommerceEngineMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/commerce-engine/",
      "epAcceleratorsMavenRepoUrl": "https://repository.elasticpath.com/nexus/content/repositories/accelerators/"
      ]
    ]
  ]

// for the syntax for the content of this file, see: https://jenkinsci.github.io/job-dsl-plugin/

listView('Jenkins') {
  jobs {
    name('build-jenkins-agents')
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

listView('Build') {
  jobs {
    name('build-deployment-package')
    name('build-core-images')
    name('build-app-images')
    name('build-docker-images')
    name('build-base-image')
    name('build-data-pop')
    name('build-mysql')
    name('build-activemq')
    name('build-infopage')
    name('build-cortex')
    name('build-search')
    name('build-cm')
    name('build-integration')
    name('build-batch')
    name('build-data-sync')
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

listView('Deployment') {
  jobs {
    name('create-or-delete-mysql-server')
    name('create-or-delete-mysql-container')
    name('run-data-pop-tool')
    name('deploy-or-delete-ep-stack')
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

listView('Test') {
  jobs {
    testJobsMap.each { testJobName, testJobConfigMap ->
      name("${testJobName}")
    }
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

buildMonitorView('Build Monitor') {
  jobs {
    regex('nightly-.+')
  }
}

pipelineJob('build-jenkins-agents') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-jenkins-agents/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
  }
  triggers {
    cron('H * * * *')
  }
}
queue('build-jenkins-agents')

pipelineJob('build-deployment-package') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-deployment-package/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce to use.')
    stringParam('epCommerceCredentialId', epCommerceCredentialId, 'The Jenkins credentials to use when checking out the ep-commerce code.')
  }
}


pipelineJob('build-docker-images') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-new-images/Jenkinsfile')
    }
  }
  parameters {
    // customization point to not have to build all jobs for every run
    booleanParam('buildBase', false, 'When checked, this Image will be built')
    booleanParam('buildDatapop', true, 'When checked, this Image will be built')
    booleanParam('buildMysql', false, 'When checked, this Image will be built')
    booleanParam('buildActivemq', false, 'When checked, this Image will be built')
    booleanParam('buildCortex', true, 'When checked, this Image will be built')
    booleanParam('buildSearch', true, 'When checked, this Image will be built')
    booleanParam('buildBatch', true, 'When checked, this Image will be built')
    booleanParam('buildIntegration', true, 'When checked, this Image will be built')
    booleanParam('buildCm', true, 'When checked, this Image will be built')
    booleanParam('buildDatasync', true, 'When checked, this Image will be built')
    booleanParam('infoPage', false, 'When checked, this Image will be built')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-core-images') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-core-images/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
  }
}

pipelineJob('build-app-images') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-app-images/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
  }
}

pipelineJob('build-base-image') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-base-image/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-data-pop') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-data-pop/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-mysql') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-mysql/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-activemq') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-activemq/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-infopage') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-infopage/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-cortex') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'cortex','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-search') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'search','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-batch') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'batch','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-integration') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'integration','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-cm') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'cm','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('build-data-sync') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/buildJobs/build-app/Jenkinsfile')
    }
  }
  parameters {
    stringParam('epAppInBuild', 'data-sync','Which EP app to build')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5 and 7.6 use 9.0.16.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', 'Build docker images with this deployment package. Optional, instead of building a deployment package with the Jenkins job use a package uploaded into a storage service.')
  }
}

pipelineJob('create-or-delete-mysql-server') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-or-delete-mysql-server/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('deleteServer', false, 'When checked, this deletes the server instead of creating it.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('serverName', '', 'The name of the server that is created. This name must be unique for all of the existing Azure Database for MySQL servers (regardless of if they were deployed by this Jenkins instance). This name must be provided later when running the data-pop-tool job and when doing deployments.')
    stringParam('kubernetesNamespace', 'default', 'The Kubernetes namespace that will store database connection information. Creates the namespace if it does not exist. To use a MySQL server created by this job an Elastic Path stack must be deployed in the same Kubernetes namespace.')
    stringParam('clusterName', kubernetesClusterName, 'The name of the AKS cluster that will store database connection information. To use a MySQL server created by this job an Elastic Path stack must be deployed in the same Kubernetes cluster.')
  }
}

pipelineJob('create-or-delete-mysql-container') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-or-delete-mysql-container/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('deleteContainer', false, 'When checked, this deletes the container instead of creating it.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('serverName', '', 'The name of the server that is created. This name must be unique for all of the existing Azure Database for MySQL servers (regardless of if they were deployed by this Jenkins instance). This name must be provided later when running the data-pop-tool job and when doing deployments.')
    stringParam('kubernetesNamespace', '', 'The namespace in the Kubernetes cluster that the MySQL container will be deployed into. This namespace must match the namespace of the deployment of the EP stack.')
    stringParam('imageTag', dockerDefaultBranch.replace('/','-'), 'The tag of the MySQL Docker image that will be deployed.')
    stringParam('clusterName', kubernetesClusterName, 'The name of the Kubernetes cluster to deploy the mysql container into.')
  }
}

pipelineJob('create-or-delete-activemq-container') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-or-delete-activemq-container/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('deleteContainer', false, 'When checked, this deletes the container instead of creating it.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('serverName', '', 'The name of the server that is created.')
    stringParam('activeMQAllowedCIDR', '127.0.0.1/32', 'The network CIDR which are allowed to access the ActiveMQ service.')
    stringParam('kubernetesNamespace', '', 'The namespace in the Kubernetes cluster that the ActiveMQ container will be deployed into. This namespace must match the namespace of the deployment of the EP stack.')
    stringParam('imageTag', dockerDefaultBranch.replace('/','-'), 'The tag of the ActiveMQ Docker image that will be deployed.')
    stringParam('dnsSubDomain', '', 'A subdomain that is prepended to the clusterName and dnsZoneName values below.\nex. dnsSubDomain=dev, clusterName=jDoeCluster, dnsZoneName=epcloud.mycompany.com results in the full DNS name of dev.jDoeCluster.epcloud.mycompany.com')
    stringParam('clusterName', kubernetesClusterName, 'The name of the Kubernetes cluster to deploy the ActiveMQ container into.')
    stringParam('dnsZoneName', rootDomainName, 'The `domainName` set in the docker-compose.yml file used during bootstrap. Can be overridden provided that DNS settings for the given domain has been manually configured.')
  }
}

pipelineJob('deploy-or-delete-ep-stack') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/deploy-or-delete-ep-stack/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('deleteStack', false, 'When checked, this deletes the stack instead of creating it.')
    choiceParam('epStackResourcingProfile', ['prod-small', 'dev'], 'The EP stack resourcing profile.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('epEnvironment', defaultEpEnvironment, 'The Elastic Path Commerce environment configuration set to use.')
    stringParam('dockerImageTag', dockerDefaultBranch.replace('/','-'), 'The image tag to use when deploying the ep-stack.')
    stringParam('kubernetesNamespace','default','The namespace in the Kubernetes cluster that the ep-stack will be deployed into. This namespace must match the namespace of the deployment of the MySQL database')
    booleanParam('includeIngresses', false, 'Creates/Deletes Ingresses to allow connections from the allowedCIDRs.')
    stringParam('cmAllowedCIDR', '127.0.0.1/32', 'The network CIDR the Ingresses allow to access the cm app service. If `includeIngresses` is false this parameter can be ignored.')
    stringParam('integrationAllowedCIDR', '127.0.0.1/32', 'The network CIDR the Ingresses allow to access the integration app service. If `includeIngresses` is false this parameter can be ignored.')
    stringParam('cortexAllowedCIDR', '127.0.0.1/32', 'The network CIDR the Ingresses allow to access the cortex app service. If `includeIngresses` is false this parameter can be ignored.')
    stringParam('studioAllowedCIDR', '127.0.0.1/32', 'The network CIDR the Ingresses allow to access the cortex studio app service. If `includeIngresses` is false this parameter can be ignored.')
    booleanParam('includeHorizontalPodAutoscalers', false, 'Creates/Deletes horizontal pod autoscalers. They automatically scale the number of pods in a replication controller, deployment or replica set.')
    booleanParam('includeDeploymentInfoPage', false, 'Creates/Deletes a page displaying cluster details, database details, and links to the deployed applications')
    stringParam('infoPageAllowedCIDR', '127.0.0.1/32', 'The network CIDR the Ingresses allow to access the info page. If `includeDeploymentInfoPage` is false this parameter can be ignored.')
    booleanParam('enableUITests', false, 'If true, UI tests are enabled for the deployment.')
    booleanParam('epChangesetsEnabled', false, 'If true, change set is enabled for deployment.')
    booleanParam('deployDstWebapp', false, 'Can only be deployed if epChangesetsEnabled is true and ep-stack is EP Commerce 7.5 or later. If true, deploys the data-sync tool webapp.')
    stringParam('targetNamespace', '', 'The namespace of the database the DST will push changes to. Leave empty if `deployDstWebapp` is false.')
    stringParam('targetJMSServerName', '', 'The JMS server of the environment that the DST will push changes to. Leave empty if `deployDstWebapp` is false.')
    stringParam('targetDBServerName', '', 'The database the DST will push changes to. Leave empty if `deployDstWebapp` is false.')
    stringParam('dnsSubDomain', '', 'A subdomain that is prepended to the clusterName and dnsZoneName values below.\nex. dnsSubDomain=dev, clusterName=jDoeCluster, dnsZoneName=epcloud.mycompany.com results in the full DNS name of dev.jDoeCluster.epcloud.mycompany.com')
    stringParam('clusterName', kubernetesClusterName, 'The name of the Kubernetes cluster to deploy the ep-stack into. Also the name of the A record and part of the full DNS name of the ep-stack.')
    stringParam('dnsZoneName', rootDomainName, 'The `domainName` set in the docker-compose.yml file used during bootstrap. Can be overridden provided that DNS settings for the given domain has been manually configured.')
    stringParam('smtpHost', '', 'The address of the SMTP server.')
    stringParam('smtpPort', '', 'The port of the SMTP server.')
    stringParam('smtpScheme', '', 'The scheme of the connection to the SMTP server.')
    stringParam('smtpUser', '', 'The username for the connection to the SMTP server.')
    nonStoredPasswordParam('smtpPass', 'The password for the connection to the SMTP server.')
    stringParam('dbServerName', '', 'The name of the database created by either create-or-delete-mysql-server or create-or-delete-mysql-container.')
    stringParam('jmsServerName', '', 'The name of the server created by create-or-delete-activemq-container')
    booleanParam('enableJmx', false, 'This enables connecting to the JMX ports of the EP apps.')
    booleanParam('enableJmxAuth', false, 'This enables user/password authentication for JMX access and generates a unique user/pass combination that is added to the ConfigMap for the EP stack deployment.')
    booleanParam('enableDebug', false, 'This enables connecting to the app JVM debug ports with the remote debugger of your IDE.')
  }
}

pipelineJob('run-data-pop-tool') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/run-data-pop-tool/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The URL of the cloudops-for-Kubernetes repository.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('serverName', '', 'The name of the database against which to run the Data Pop Tool.\nThe database must have its connection parameters as Secrets in Kubernetes.')
    stringParam('jmsServerName', '', 'The name of the server created by create-or-delete-activemq-container')
    stringParam('kubernetesNamespace', '', 'The Kubernetes namespace in which the database specified by serverName was created.\nThe job will run the data-pop-tool inside the same namespace.')
    stringParam('dataPopToolCommand', '', 'The data-pop-tool command to run on the database.\nMust be either reset-db or update-db.')
    stringParam('epEnvironment', defaultEpEnvironment, 'The name of the environment folder containing configuration specifying which EP data will be populated in database.\nMust be one of the environment folders in the deployment package with which the data-pop-tool was built.')
    stringParam('imageTag', dockerDefaultBranch.replace('/','-'), 'The tag of the data-pop-tool image that will be used to populate the MySQL database.')
    stringParam('clusterName', kubernetesClusterName, 'The name of the kubernetes cluster where the mysql database is located.')
  }
}

pipelineJob('run-cortex-system-tests') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/run-cortex-system-tests/Jenkinsfile')
    }
  }
  parameters {
    stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which the target EP stack is running.')
    stringParam('jmsServerName', '', 'The name of the target JMS server.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce to use.')
    stringParam('epCommerceCredentialId', epCommerceCredentialId, 'The Jenkins credentials to use when checking out the ep-commerce code.')
  }
}

// since our test jobs share a lot of common configuration, the common config is included below while
// the different config is stored in testJobsMap
for(testJobsMapEntry in testJobsMap) {
  def testJobName = testJobsMapEntry.key
  def testJobConfigMap = testJobsMapEntry.value
  def testJobParametersMap = testJobConfigMap.get("parameters")
  pipelineJob("${testJobName}") {
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
      stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which to deploy the pod which will bootstrap CloudOps for Kubernetes.')
      booleanParam('cleanupResourceGroup', true, 'Clean up the resource group generated by this job.')
      booleanParam('runCortexSystemTests', false, 'Run the Cortex system tests on the deployed ep-stacks.')
      stringParam('resourceGroup', testJobParametersMap.get("resourceGroup"), '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('kubernetesClusterName', testJobParametersMap.get("kubernetesClusterName"), 'For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('region', 'us-west-2', '[AWS] The region of AWS account.')
      stringParam('eksInstanceType', 'm5a.xlarge', '[AWS] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('eksNodeCount', '1', '[AWS] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('location', 'westus2', '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('aksNodeVMSize', 'Standard_B4ms', '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('aksNodeCount', '1', '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('domainName', testJobParametersMap.get("domainName"), 'A subdomain of the domain name in zoneForNSRecord. For parameter details, see the CloudOps for Kubernetes docker-compose file.')
      stringParam('zoneForNSRecord', "${cloud}.epcloudops.com", 'The name of the DNS Zone where name server records will be created to point to the DNS Zone created by the bootstrap process.')
      stringParam('resourceGroupForParentZone', 'ImmortalResourceGroup', '[Azure] The Resource Group that zoneForNSRecord is a part of.')
      credentialsParam('gitReposPrivateKey') {
        type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
        required()
        defaultValue('gitCredentialId')
        description('Private SSH key authorized to clone from repositories specified by cloudOpsForKubernetesRepoURL, epCommerceRepoURL and dockerRepoURL.')
      }
      stringParam('jenkinsIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Jenkins. \nex. "1.2.3.4/32,2.3.4.5/32"')
      stringParam('nexusIngressCIDR', '', 'A comma separated list of IPs that are allowed to access Nexus. \nex. "1.2.3.4/32,2.3.4.5/32"')
      stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to test.')
      stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The Git repo from which to pull CloudOps for Kubernetes code.')
      stringParam('epCommerceBranch', testJobParametersMap.get("epCommerceBranch"), 'The branch of EP Commerce to test.')
      stringParam('epCommerceRepoURL', testJobParametersMap.get("epCommerceRepoURL"), 'The Git repo from which to pull EP Commerce code.')
      stringParam('dockerBranch', dockerDefaultBranch, 'The branch of EP docker to test.')
      stringParam('dockerRepoURL', dockerRepoURL, 'The Git repo from which to pull EP docker code.')
      stringParam('gitSSHHostKey', defaultGitServerHostKey, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('awsAccessKeyId', '', '[AWS] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      simpleParam('hudson.model.PasswordParameterDefinition', 'awsSecretAccessKey', '', '[AWS] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('azureSubscriptionId', defaultAzureSubscriptionId, '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('azureServicePrincipalTenantId', defaultAzureSpTenantId, '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('azureServicePrincipalAppId', '', '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      simpleParam('hudson.model.PasswordParameterDefinition', 'azureServicePrincipalPassword', '', '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('epRepositoryUser', defaultEpRepositoryUser, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      simpleParam('hudson.model.PasswordParameterDefinition', 'epRepositoryPassword', defaultEpRepositoryPassword, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('epCortexMavenRepoUrl', testJobParametersMap.get("epCortexMavenRepoUrl"), 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('epCommerceEngineMavenRepoUrl', testJobParametersMap.get("epCommerceEngineMavenRepoUrl"), 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('epAcceleratorsMavenRepoUrl', testJobParametersMap.get("epAcceleratorsMavenRepoUrl"), 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('oracleJdkDownloadUrl', defaultJdkDownloadUrl, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('jdkFolderName', defaultJdkFolderName, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
      stringParam('tomcatVersion', tomcatVersion, 'For parameter details, see the CloudOps for Kubernetes docker-compose files.')
    }
    triggers {
        cron(testJobConfigMap.get("build-schedule"))
    }
  }
}

pipelineJob('create-additional-AKS-cluster') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('${cloudOpsForKubernetesRepoURL}')
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-additional-AKS-cluster/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The URL of the cloudops-for-kubernetes repository.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('aksNodeVMSize', 'Standard_B4ms', 'The starting number of virtual machines in the AKS cluster.')
    stringParam('aksNodeCount', '5', 'The size of the virtual machines in the AKS cluster.')
    stringParam('clusterName', '', 'The name of the AKS cluster to be created by this job.')
    stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which to deploy the pod which will create the new cluster.')
    stringParam('azureSubscriptionId', defaultAzureSubscriptionId, '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
    stringParam('azureServicePrincipalTenantId', defaultAzureSpTenantId, '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
    stringParam('azureServicePrincipalAppId', defaultAzureSpAppId, 'For parameter details, see the CloudOps for Kubernetes docker-compose file.')
    simpleParam('hudson.model.PasswordParameterDefinition', 'azureServicePrincipalPassword', defaultAzureSpPassword, '[Azure] For parameter details, see the CloudOps for Kubernetes docker-compose files.')
    stringParam('baseName', '', 'For parameter details, see the CloudOps for Kubernetes docker-compose file.')
    stringParam('location', '', 'For parameter details, see the CloudOps for Kubernetes docker-compose file.')
    stringParam('domainName', '', 'For parameter details, see the CloudOps for Kubernetes docker-compose file.')
  }
}

listView('Account Management') {
  jobs {
    name('build-docker-images-account-management')
    name('create-or-delete-account-management-mysql-container')
    name('register-external-activemq-service')
    name('create-or-delete-account-management-stack')
    name('deploy-account-management-pipeline')
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

pipelineJob('create-or-delete-account-management-mysql-container') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url(cloudOpsForKubernetesRepoURL)
            credentials(cloudOpsForKubernetesCredentialId)
          }
          extensions {
            cloneOptions {
              shallow(true)
              depth(10)
            }
            relativeTargetDirectory('cloudops-for-kubernetes')
          }
          branch('${cloudops_for_kubernetes_branch}')
        }
      }
      lightweight(false)
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-or-delete-account-management-mysql-container/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('plan_mode', true, 'Run Terraform in plan mode and prompt you to continue. This works in both apply and destroy modes.')
    booleanParam('destroy_mode', false, 'Run Terraform in destroy mode. This also deletes Terraform workspaces and Kubernetes namespaces if empty.')
    stringParam('TF_VAR_database_name', '', 'The name of the database that is created.')
    stringParam('TF_VAR_kubernetes_namespace', '', 'The namespace in the Kubernetes cluster that the MySQL container will be deployed into.')
    stringParam('cluster_name', kubernetesClusterName, 'The name of the Kubernetes cluster to deploy the MySQL container into.')
    stringParam('cloudops_for_kubernetes_branch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to use.')
  }
}

pipelineJob('build-docker-images-account-management') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url(cloudOpsForKubernetesRepoURL)
            credentials(cloudOpsForKubernetesCredentialId)
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-docker-images-account-management/Jenkinsfile')
    }
  }
  parameters {
      stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
      stringParam('releasePackageUrl', defaultAmReleasePackageUrl, 'The URL for the Account Management release package.')
      stringParam('imageTag', '', 'The image tag for the Account Management docker images.')
  }
}


pipelineJob('register-external-activemq-service') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url(cloudOpsForKubernetesRepoURL)
            credentials(cloudOpsForKubernetesCredentialId)
          }
          extensions {
            cloneOptions {
              shallow(true)
              depth(10)
            }
            relativeTargetDirectory('cloudops-for-kubernetes')
          }
          branch('${cloudops_for_kubernetes_branch}')
        }
      }
      lightweight(false)
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/register-external-activemq-service/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('plan_mode', true, 'Run Terraform in plan mode and prompt you to continue. This works in both apply and destroy modes.')
    booleanParam('destroy_mode', false, 'Run Terraform in destroy mode. This also deletes Terraform workspaces and Kubernetes namespaces if empty.')
    stringParam('TF_VAR_service_name', '', 'The name of the service that can be referenced in other Jenkins jobs.')
    stringParam('TF_VAR_jms_url', '', 'The JMS URL of the ActiveMQ service.')
    stringParam('TF_VAR_kubernetes_namespace', '', 'The Kubernetes namespace in which to register the service. Access information will only be available in this namespace.')
    stringParam('cluster_name', kubernetesClusterName, 'The Kubernetes cluster in which to register the service. Access information will only be available in this cluster.')
    stringParam('cloudops_for_kubernetes_branch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to use.')
  }
}

pipelineJob('create-or-delete-account-management-stack') {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            name('origin')
            url(cloudOpsForKubernetesRepoURL)
            credentials(cloudOpsForKubernetesCredentialId)
          }
          extensions {
            cloneOptions {
              shallow(true)
              depth(10)
            }
            relativeTargetDirectory('cloudops-for-kubernetes')
          }
          branch('${cloudops_for_kubernetes_branch}')
        }
      }
      lightweight(false)
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-or-delete-account-management-stack/Jenkinsfile')
    }
  }

  parameters {
    booleanParam('plan_mode', true, 'Run Terraform in plan mode and prompt you to continue. This works in both apply and destroy modes.')
    booleanParam('destroy_mode', false, 'Run Terraform in destroy mode. This also deletes Terraform workspaces and Kubernetes namespaces if empty.')
    stringParam('TF_VAR_docker_tag', '', 'The Account Management Docker images to use. Must match the value used when building Docker images.')
    stringParam('TF_VAR_account_management_database_name', '', 'The database created by the create-or-delete-account-management-mysql-container job to use with the Account Management stack.')
    stringParam('TF_VAR_account_management_activemq_name', '', 'The ActiveMQ service created by create-or-delete-activemq-container job or registered by register-external-activemq-service.')
    stringParam('TF_VAR_allowed_cidrs', '', 'Comma-separated list of CIDRs allowed to access Account Management services.')
    stringParam('TF_VAR_kubernetes_namespace', '', 'The Kubernetes namespace in which to deploy the Account Management stack. It must match the namespace of the database.')
    booleanParam('TF_VAR_include_keycloak', false, '(Optional) Include a Keycloak Helm release. Required if external OpenID Connect (OIDC) parameters are not set. NOTE: Only use this Keycloak identity provider in test deployments.')
    stringParam('TF_VAR_keycloak_database_name', '', '(Optional) The database created by the create-or-delete-account-management-mysql-container job to use with Keycloak. Required if TF_VAR_include_keycloak is true.')
    nonStoredPasswordParam('TF_VAR_private_jwt_key', 'A private JWT key. Review the Account Management documentation for instructions on generating the key.')
    nonStoredPasswordParam('TF_VAR_api_access_token', '(Optional) An API access token that can authenticate all API calls to Account Management. Will be generated if not provided.')
    stringParam('TF_VAR_oidc_discovery_url', '', '(Optional) The OpenID Connect discovery URL of an Identity Provider. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_oidc_client_id', '', '(Optional) The OpenID Connect client ID of an Identity Provider. Required if TF_VAR_include_keycloak is false.')
    nonStoredPasswordParam('TF_VAR_oidc_client_secret', '(Optional) The OpenID Connect client secret of an Identity Provider. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_oidc_token_scope', '', '(Optional) The OpenID Connect token scope of an Identity Provider. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_oidc_group_key', '', '(Optional) The OpenID Connect group key of an Identity Provider. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_oidc_group_value_for_associates', '', '(Optional) The OpenID Connect group value for Associate type Account Management users. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_oidc_group_value_for_seller_users', '', '(Optional) The OpenID Connect group value for Seller type Account Management users. Required if TF_VAR_include_keycloak is false.')
    stringParam('TF_VAR_kubernetes_cluster_name', kubernetesClusterName, 'The name of the Kubernetes cluster in which to deploy the Account Management stack.')
    stringParam('cloudops_for_kubernetes_branch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to use.')
  }
}

pipelineJob("deploy-account-management-pipeline") {
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url(cloudOpsForKubernetesRepoURL)
            credentials(cloudOpsForKubernetesCredentialId)
          }
          extensions {
            cloneOptions {
              shallow(true)
              depth(10)
            }
            relativeTargetDirectory('cloudops-for-kubernetes')
          }
          branch('${cloudops_for_kubernetes_branch}')
        }
      }
      lightweight(false)
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/cloudops-for-kubernetes-account-management-ci/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('plan_mode', true, 'If set, certain jobs will wait for user confirmation before proceeding.')
    stringParam('kubernetes_namespace', '', 'The Kubernetes namespace where the Account Management stack is deployed.')
    stringParam('kubernetes_cluster_name', kubernetesClusterName, 'The Kubernetes cluster where the Account Management stack is deployed.')
    stringParam('docker_image_tag', '', '(Optional) The Account Management Docker images to deploy. Required if relase_package_url is not set. If both are set, the pipeline builds Docker images using the release package and tags the images using the value in docker_image_tag.')
    stringParam('release_package_url', '', '(Optional) The URL of the Account Management release package to deploy. Required if docker_image_tag is not set. If both are set, the pipeline builds Docker images using the release package and tags the images using the value in docker_image_tag.')
    stringParam('activemq_name', '', 'The ActiveMQ service created by create-or-delete-activemq-container job or registered by register-external-activemq-service.')
    stringParam('allowed_cidrs', '', 'A comma-separated list of IP CIDRs allowed to access the Account Management services.')
    nonStoredPasswordParam('TF_VAR_private_jwt_key', 'A private JWT key. Review the Account Management documentation for instructions on generating the key.')
    nonStoredPasswordParam('am_api_access_token', '(Optional) An API access token that can authenticate all API calls to Account Management. Will be generated if not provided.')
    stringParam('oidc_discovery_url', '', 'The OpenID Connect discovery URL of an Identity Provider.')
    stringParam('oidc_client_id', '', 'The OpenID Connect client ID of an Identity Provider.')
    nonStoredPasswordParam('oidc_client_secret', 'The OpenID Connect client secret of an Identity Provider.')
    stringParam('oidc_token_scope', '', 'The OpenID Connect token scope of an Identity Provider.')
    stringParam('oidc_group_key', '', 'The OpenID Connect group key of an Identity Provider.')
    stringParam('oidc_group_value_for_associates', '', 'The OpenID Connect group value for Associate type Account Management users.')
    stringParam('oidc_group_value_for_seller_users', '', 'The OpenID Connect group value for Seller type Account Management users.')
    booleanParam('delete_stack', true, 'If set, the job will cleanup the stack that is created after the pipeline is complete.')
    stringParam('cloudops_for_kubernetes_branch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to use for the Jenkinsfile and Terraform configuration.')
  }
}

// bootstrapping extra repos


if(bootstrapExtrasPropertiesFile.exists()) {
  bootstrapExtrasPropertiesString=bootstrapExtrasPropertiesFile.text.trim()
  def jsonSlurper = new JsonSlurper()
  def bootstrapExtrasPropertiesJsonObject = jsonSlurper.parseText(bootstrapExtrasPropertiesString)
  def extraGitRepos = bootstrapExtrasPropertiesJsonObject.git_repos.keySet()
  for (extraGitRepo in extraGitRepos) {

     def extraGitRepoConfig = bootstrapExtrasPropertiesJsonObject.git_repos.getAt(extraGitRepo)
     def extraGitRepoUrl = extraGitRepoConfig.repo_url
     def extraBootstrapJobName = 'bootstrap-' + extraGitRepo

     println "Bootstrapping extra git repo '" + extraGitRepoUrl + "'"

     freeStyleJob(extraBootstrapJobName) {
        scm {
          git {
            remote {
              name('origin')
              url(extraGitRepoConfig.repo_url)
              credentials('gitCredentialId')
            }
            extensions {
              cloneOptions {
                shallow(true)
                depth(10)
              }
            }
            branch(extraGitRepoConfig.default_branch)
          }
        }
        steps {
          dsl {
            external(extraGitRepoConfig.bootstrap_dsl_groovy_path)
          }
        }
     }
     queue(extraBootstrapJobName)
  }
}
