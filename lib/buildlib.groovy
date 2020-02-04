import java.time.LocalDateTime
import groovy.lang.Binding

eplib = load "cloudops-for-kubernetes/lib/eplib.groovy"

def downloadDeploymentPackageFromUrl(String deploymentPackageUrl) {
  sh """
  curl -L -v "${params.deploymentPackageUrl}" > /root/deploymentpackage.zip
  """
}

def downloadDeploymentPackageFromJenkins(String epCommerceRepoURL,String epCommerceBranch) {
  copyArtifacts(projectName: 'build-deployment-package', filter: 'output.json', , target: '.',
    parameters: "epCommerceRepoURL=" + epCommerceRepoURL + ",epCommerceBranch=" + epCommerceBranch);
  def buildDeploymentPackageOutput = readJSON file: 'output.json'
  assert buildDeploymentPackageOutput['epCommercePlatformAndExtensionVersion'] != ''
  def netrcFile = new File("/root/.netrc")
  netrcFile.write("machine " + eplib.nexusBaseUri + " login " + eplib.nexusRepoUsername + " password " + eplib.nexusRepoPassword + "\n")
  sh """
  curl -L -v "${eplib.nexusBaseUri}/nexus/service/local/artifact/maven/redirect?r=ep-releases&g=com.elasticpath.extensions&a=ext-deployment-package&p=zip&v=${buildDeploymentPackageOutput['epCommercePlatformAndExtensionVersion']}" > /root/deploymentpackage.zip
  """
}

def buildAndPushImage(String epAppInBuild) {
  sharedSteps()
  cloneDockerCode()
  downloadDeploymentPackage()
  sh """
    sed -i -e "s/`grep 'epApps' docker/EpImageBuilder/config/ep-image-builder.conf | awk -F'"' '{print \$2}'`/${epAppInBuild}/g" docker/EpImageBuilder/config/ep-image-builder.conf
    cd docker/EpImageBuilder/
    ./EpImageBuilder.sh --configFile config/ep-image-builder.conf --tomcatversion ${params.tomcatVersion} --deploymentPackage /root/deploymentpackage.zip --dockerRegistry ${dockerRegistryAddress} --namespace ep --dockerImageTag "${dockerImageTag}" --useImg
  """
}

// the line below is required because of a quirk in how Jenkins + Groovy handles dynamically loaded code
return this