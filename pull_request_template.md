### Description
Replace this section with 2-3 sentences describing your PR. The description should cover:
- What the PR accomplishes, not how. How is answered in the diffs.
- Why the PR exists.
- Any high level concerns related to the PR.

**An example of a good description:**

This PR refactors the builds of our Docker images so that more of the common parts are in our Tomcat base image. This moves us closer to the goal of having a simpler and faster build of our Docker images which can eventually be moved into a shared repo. There is still more work to be done (e.g. moving the jdbc jars) which will require BaseImageBuilder.sh to be given a copy of the deployment package (see CLOUD-387).

### How was this PR tested?
- [ ] Ran through a [C4K CI pipelines](https://github.elasticpath.net/DevOps/Internal-DevOps-Docs/wiki/Using-the-C4K-Pipelines)
    - [C4K AWS CI pipeline](https://jenkins.hub.awsci.aws.epcloudops.com/job/on-demand-ci/)
    - [C4K Azure CI pipeline](https://jenkins.hub.azureci.azure.epcloudops.com/job/on-demand-ci/)
    - **paste link to AWS CI pipeline run here**
    - **paste link to Azure CI pipeline run here**

### Does this PR have QA Requirements?
- [ ] - Yes
    - [ ] Documented test steps on Jira
- [ ] - No

### Does this PR require documentation?
- [ ] - Yes
  - [ ] Customer facing doc?
  - [ ] Internal only doc?
  - [ ] Release notes?
      - should include Release version, component/bug fix, related Jira ticket
- [ ] - No

### Does this PR affect other teams?

#### This PR won't disrupt other teams checklist

This PR will:
- Require existing clusters to be upgraded or redeployed from scratch
    - [ ] - Yes
        - [ ] and I have consulted with the Next Gen Saas team, and they will recreate their clusters
        - [ ] and I have consulted with the CloudOps team, and they will recreate their clusters
    - [ ] - No
    - [ ] - I'm not sure and need guidance from a CloudOps reviewer
- modify or delete existing parameters in docker-compose.yml
    - [ ] - Yes
        - [ ] and I have consulted with the Next Gen Saas team, and they will make changes to their infrastructure accordingly
    - [ ] - No
- modify or delete function in lib/eplib.groovy
    - [ ] - Yes
        - [ ] and I have consulted with the Next Gen Saas team, and they do not use the affected functions or will make changes to their infrastructure accordingly
    - [ ] - No

### Does this PR require review from someone outside the team?
- Architecture?
    - [ ] - Yes
    - [ ] - No
- Product?
    - [ ] - Yes
    - [ ] - No
- Other Devs/QAs outside our team?
    - [ ] - Yes
    - [ ] - No
- Professional Services?
    - [ ] - Yes
    - [ ] - No
