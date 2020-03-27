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
def tagSafeBranch = dockerDefaultBranch.replace('/','-')
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

listView('Commerce Build') {
  jobs {
    name('build-deployment-package')
    name('build-core-images')
    name('build-commerce-images')
    name('build-selected-docker-images')
    name('build-pipeline')
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

listView('Commerce Deploy') {
  jobs {
    name('create-or-delete-mysql-server')
    name('create-or-delete-mysql-container')
    name('create-or-delete-activemq-container')
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
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
  }
  triggers {
    cron('H 4 * * *')
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
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce to use.')
    stringParam('epCommerceCredentialId', epCommerceCredentialId, 'The Jenkins credentials to use when checking out the ep-commerce code.')
  }
}

pipelineJob('build-selected-docker-images') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-selected-docker-images/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('buildBase', false, 'Build the CloudOps base images')
    booleanParam('buildDatapop', true, 'Build the data-pop-tool image')
    booleanParam('buildMysql', false, 'Build the CloudOps mysql image')
    booleanParam('buildActivemq', false, 'Build the CloudOps activemq image')
    booleanParam('buildCortex', true, 'Build the cortex image')
    booleanParam('buildSearch', true, 'Build the search image')
    booleanParam('buildBatch', true, 'Build the batch image')
    booleanParam('buildIntegration', true, 'Build the integration image')
    booleanParam('buildCm', true, 'Build the cm image')
    booleanParam('buildDatasync', true, 'Build the data-sync image')
    booleanParam('infoPage', false, 'Build the info-page image')
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker images')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfiles.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for certain Dockerfiles.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The EP Commerce branch. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat base image to build and/or use. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
    stringParam('deploymentPackageUrl', '', '(Optional) Build Elastic Path application Docker images with this deployment package instead of the package built by the last build-deployment-package job run with the provided Commerce branch.')
  }
}

pipelineJob('build-core-images') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-core-images/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker images')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to build the base Tomcat image with. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of Cloudops for Kubernetes to use for the Jenkinsfiles.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of EP Docker to use for the Dockerfiles.')
  }
}

pipelineJob('build-commerce-images') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-commerce-images/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker images')
    stringParam('tomcatVersion', tomcatVersion, 'The version of Tomcat to download and use. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The EP Commerce branch. This is used to find the last successful build of the build-deployment-package job with the same value.')
  }
}

pipelineJob('build-pipeline') {
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
              depth(1)
            }
            relativeTargetDirectory('cloudops-for-kubernetes')
          }
          branch('${cloudOpsForKubernetesBranch}')
        }
      }
      lightweight(false)
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/build-pipeline/Jenkinsfile')
    }
  }
  parameters {
    booleanParam('buildPackage', true, 'whether or not to build new deployment package for this job')
    booleanParam('buildCoreContainers', true, 'whether or not to build new core docker containers for this job')
    booleanParam('buildCommerceContainers', true, 'whether or not to build new commerce docker containers for this job')
    booleanParam('runBlockingTests', true, 'whether or not to run blocking tests for this job')
    booleanParam('runNonBlockingTests', true, 'whether or not to run non-blocking tests for this job')
    booleanParam('deployActiveMq', true, 'whether or not to build deploy activemq container for this job')
    booleanParam('deployMySQL', true, 'whether or not to deploy mysql container for this job')
    booleanParam('deployEP', true, 'whether or not to deploy ep stack for this job')
    booleanParam('runDataPop', true, 'whether or not to run data pop for this job')
    booleanParam('deleteOldStack', true, 'whether or not to delete the previous stack for this build.')
    booleanParam('deleteNewStack', true, 'whether or not to delete the newly created EP stack if it passes all cucumber tests.')
    booleanParam('deleteActiveMQ', true, 'Whether or not to delete the old ActiveMQ container along with the EP stack.  Does nothing if deleteOldStack is set to false.')
    booleanParam('deleteMySQLContainer', true, 'Whether or not to delete the old MySQL container along with the EP stack.  Does nothing if deleteOldStack is set to false.')
    stringParam('cloudOpsForKubernetesRepoURL', cloudOpsForKubernetesRepoURL, 'The repo URL of the cloudops-for-kubernetes code.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('dockerRepoURL', dockerRepoURL, 'The repo URL of the docker code.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The branch of docker to use.')
    stringParam('dockerCredentialId', dockerCredentialId, 'The Jenkins credentials to use when checking out the EP docker code.')
    stringParam('epCommerceRepoURL', epCommerceRepoURL, 'The repo URL of the ep-commerce code. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('allowedCidr','','The CIDR of IPs which are allowed access to this deployment of the EP stack')
    stringParam('dnsZoneName', rootDomainName)
    stringParam('clusterName','','The name of the kubernetes cluster to deploy to')
    stringParam('dnsSubDomain','','The DNS subdomain to use for the environment.')
    stringParam('epEnvironment','ci','The ep environment to deploy using datapop')
    stringParam('dataPopToolCommand', '', 'The data-pop-tool command to run on the database.\nMust be either reset-db or update-db.')
    stringParam('kubernetesNamespace', 'default', 'The Kubernetes namespace that will store database connection information. Creates the namespace if it does not exist. To ensure the MySQL server is deleted by this job an Elastic Path stack must be deployed in the same Kubernetes namespace.')
  }
}

pipelineJob('build-data-pop') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-data-pop/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker image')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for the Dockerfile.')
    stringParam('tomcatVersion', tomcatVersion, 'The Tomcat version to build the image with. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The EP Commerce branch. This is used to find the last successful build of the build-deployment-package job with the same value.')
    stringParam('deploymentPackageUrl', '', '(Optional) Build the image with this deployment package instead of the package defined by epCommerceBranch')
  }
}

pipelineJob('build-base-image') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-base-image/Jenkinsfile')
    }
  }
  parameters {
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for the Dockerfiles.')
    stringParam('tomcatVersion', tomcatVersion, 'The Tomcat version to build the Tomcat base image with. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
  }
}

pipelineJob('build-mysql') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-mysql/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker image')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for the Dockerfile.')
  }
}

pipelineJob('build-activemq') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-activemq/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker image')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
    stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for the Dockerfile.')
  }
}

pipelineJob('build-infopage') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-infopage/Jenkinsfile')
    }
  }
  parameters {
    stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker image')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile and Dockerfile.')
  }
}

def appDockerBuildMap = [
  "cortex",
  "search",
  "batch",
  "integration",
  "cm",
  "data-sync"
]

for(app in appDockerBuildMap) {
  pipelineJob("build-${app}") {
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
            branch('${cloudOpsForKubernetesBranch}')
          }
        }
        lightweight(false)
        scriptPath('cloudops-for-kubernetes/jenkins/jobs/docker-build-jobs/build-app/Jenkinsfile')
      }
    }
    parameters {
      stringParam('imageTag', tagSafeBranch, 'Value to tag the built Docker image')
      stringParam('tomcatVersion', tomcatVersion, 'The Tomcat base image to use. For EP Commerce 7.5, 7.6 and 8.0 use 9.0.16.')
      stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The CloudOps for Kubernetes branch to use for the Jenkinsfile.')
      stringParam('dockerBranch', dockerDefaultBranch, 'The EP Docker branch to use for the Dockerfile.')
      stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The EP Commerce branch. This is used to find the last successful build of the build-deployment-package job with the same value.')
      stringParam('deploymentPackageUrl', '', '(Optional) Build Docker images with this deployment package instead of finding a deployment package based on the value of epCommerceBranch.')
      stringParam('epAppInBuild', app,'The EP application to build')
    }
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
    stringParam('imageTag', tagSafeBranch, 'The tag of the MySQL Docker image that will be deployed.')
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
    stringParam('imageTag', tagSafeBranch, 'The tag of the ActiveMQ Docker image that will be deployed.')
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
    stringParam('dockerImageTag', tagSafeBranch, 'The image tag to use when deploying the ep-stack.')
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
    stringParam('imageTag', tagSafeBranch, 'The tag of the data-pop-tool image that will be used to populate the MySQL database.')
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

pipelineJob('run-select-commerce-tests') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/run-select-commerce-tests/Jenkinsfile')
    }
  }
  parameters {
    stringParam('kubernetesNamespace', 'default', 'Kubernetes namespace in which the target EP stack is running.')
    stringParam('SELECTED_TEST_STRING', '!commerce-engine/core/ep-core-itests,!extensions/cortex/system-tests/cucumber', 'The string value of the commerce tests to run.')
    stringParam('cloudOpsForKubernetesBranch', cloudOpsForKubernetesDefaultBranch, 'The branch of cloudops-for-kubernetes to use.')
    stringParam('epCommerceBranch', epCommerceDefaultBranch, 'The branch of ep-commerce to use.')
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
    name('create-database-and-user-in-external-database-instance')
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
    stringParam('TF_VAR_oidc_token_scope', '', '(Optional) The OpenID Connect token scope of an Identity Provider.')
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

pipelineJob('create-database-and-user-in-external-database-instance') {
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
      scriptPath('cloudops-for-kubernetes/jenkins/jobs/create-database-and-user-in-external-database-instance/Jenkinsfile')
    }
  }
  parameters {
    stringParam('target_subscription_id', defaultAzureSubscriptionId, '[Azure] The ID of the subscription group the external database is in. Defaults to the subscription ID CloudOps for Kubernetes was deployed in.')
    stringParam('TF_VAR_target_resource_group', '', '[Azure] The name of the resource group the external database is in. Defaults to the resource group CloudOps for Kubernetes was deployed in.')
    stringParam('TF_VAR_azure_location', '', '[Azure] The location of the external database.')
    stringParam('TF_VAR_root_username', '', 'The root username of the external database instance. Can be found in the Kubernetes secret created by the job `create-or-delete-mysql-server` or in the CloudOps for AWS Consul config store.' )
    simpleParam('hudson.model.PasswordParameterDefinition', 'TF_VAR_root_password', '', 'The root password of the external database instance. Can be found in the Kubernetes secret created by the job `create-or-delete-mysql-server` or in the CloudOps for AWS config store.')
    stringParam('TF_VAR_database_hostname', '', 'The name of the server created by the job `create-or-delete-mysql-server` or the DB identifier of an RDS instance created by a CloudOps for AWS Author and Live environment.')
    stringParam('TF_VAR_database_server_url', '', 'The endpoint of the server to connect to. Found in the web console of your cloud provider. An Amazon RDS endpoint would have the format `sample-database.cluster-asdf.us-west-2.rds.amazonaws.com`. An Azure MySQL server endpoint is the server name with the format `sample-database.azure.database.azure.com`.')
    stringParam('TF_VAR_database_name', '', 'The name of the database. Will be created by this job if it does not exist or no value is provided.')
    stringParam('TF_VAR_database_username', '', 'The username of the external database. Will be created by this job if it does not exist or no value is provided.')
    simpleParam('hudson.model.PasswordParameterDefinition', 'TF_VAR_database_password', '', 'The password of the external database. Will be created by this job if it does not exist or no value is provided.')
    stringParam('TF_VAR_kubernetes_namespace', '', 'The Kubernetes namespace in which to register the service. Access information will only be available in this namespace.')
    stringParam('cluster_name', kubernetesClusterName, 'The Kubernetes cluster in which to register the service. Access information will only be available in this cluster.')
    stringParam('cloudops_for_kubernetes_branch', cloudOpsForKubernetesDefaultBranch, 'The branch of CloudOps for Kubernetes to use.')
  }
}