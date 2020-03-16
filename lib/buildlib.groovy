import java.time.LocalDateTime
import groovy.lang.Binding
import hudson.model.Result
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

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

def validateDockerTag(String tag, String parameterName) {
  if(! tag) throw new Exception("${parameterName} parameter must be set")
  if(tag.contains("/")) throw new Exception("${parameterName} parameter must not have slashes")
}

@NonCPS
String getLogFromRunWrapper(RunWrapper runWrapper, int logLines) {
  runWrapper.getRawBuild().getLog(logLines).join('\n    ')
}

def buildLocalJob(String jobName, def parameters) {
  // do not fail current job immediatly after triggered job fails
  RunWrapper buildResult = build(
    job: jobName,
    parameters: parameters,
    propagate: false,
    wait: true
  )

  // output logs
  echo buildlib.getLogFromRunWrapper(buildResult, 10000)

  // now fail if needed
  buildJobResult = buildResult.getCurrentResult()
  if (buildJobResult != Result.SUCCESS.toString()) {
    error "failed building Docker image: ${buildJobResult}"
  }
}

// the line below is required because of a quirk in how Jenkins + Groovy handles dynamically loaded code
return this
