---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 14 # Update this with PR number/ID. No leading zeros
rfc_feature_name: rework-handling-of-test-results # Use kebab-case
title: "RFC-0014: rework-handling-of-test-results" # Update this with PR number/ID and feature name. Use leading zeros
rfc_author_username: Alexamakans
rfc_author_name: Alexander Fougner # Or same as username, if you wish

# Leave these. Collaborator changes this before merging
impl_issue_id: 0
impl_issue_repo: iver-wharf/wharf-api
last_modified_date: YYYY-MM-DD
---

# {{page.title}}

- RFC PR: [iver-wharf/rfcs#{{page.pr_id}}](https://github.com/iver-wharf/rfcs/pulls/{{page.pr_id}})
- Feature name: `{{page.rfc_feature_name}}`
- Author: {{page.rfc_author_name}} ([@{{page.rfc_author_username}}](https://github.com/{{page.rfc_author_username}}))
- Implementation issue: [{{page.impl_issue_repo}}#{{page.impl_issue_id}}](https://github.com/{{page.impl_issue_repo}}/issues/{{page.impl_issue_id}})
- Implementation status: ![GitHub issue state](https://img.shields.io/github/issues/detail/state/{{page.impl_issue_repo}}/{{page.impl_issue_id}}?{{page.shields_io_query_params}})

## Summary

The intent is to avoid filtering and parsing test result files (TRX)
from the generated artifacts each time we want to display them or a
summary.

We also want to display more detailed test result summaries in wharf-web.
For this we will need to also store the messages that the tests produce.
At the very least for failed tests.

## Motivation

The Status field in wharf-web's project view (Failed/Completed)
currently calls an endpoint that asks the server to fetch all TRX files
for the build, and take the most recent one. Then it parses the file to
see how many failed/completed tests there were.
It does this for every build in the view, every time it is refreshed.
This leads to unnecessary requests and computation. This, in turn, slows
down the response times and increases the API load.

Having the tests' error messages is also pretty much a necessity when trying
to fix them. Currently, there is no way to ask the API for them.

## Related GitHub issues

- wharf-api [#11](https://github.com/iver-wharf/wharf-api/issues/11) [#17](https://github.com/iver-wharf/wharf-api/issues/17)
- wharf-web [#13](https://github.com/iver-wharf/wharf-web/issues/13)

## Explanation

### wharf-api

The `POST /build/{buildid}/artifact` endpoint handles inserting artifacts, same
as before. However, if it's a TRX file, one should call the
`POST /build/{buildid}/test-results` endpoint instead. This tells the server
to parse them as well, creating several `TestResult`s and one `TestResultSummary`
per TRX file.

The summaries get inserted into the database table `test_result_summary`.\
The results get inserted into the database table `test_result`.

![Database structure](../_assets/wharf-db-graph.png)

```diff
// database_models.go
type Build struct {
  BuildID     uint         `gorm:"primaryKey" json:"buildId"`
  StatusID    BuildStatus  `gorm:"not null" json:"statusId"`
  ProjectID   uint         `gorm:"not null;index:build_idx_project_id" json:"projectId"`
  Project     *Project     `gorm:"foreignKey:ProjectID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
  ScheduledOn *time.Time   `gorm:"nullable;default:NULL" json:"scheduledOn" format:"date-time"`
  StartedOn   *time.Time   `gorm:"nullable;default:NULL" json:"startedOn" format:"date-time"`
  CompletedOn *time.Time   `gorm:"nullable;default:NULL" json:"finishedOn" format:"date-time"`
  GitBranch   string       `gorm:"size:300;default:'';not null" json:"gitBranch"`
  Environment null.String  `gorm:"nullable;size:40" json:"environment" swaggertype:"string"`
  Stage       string       `gorm:"size:40;default:'';not null" json:"stage"`
  Params      []BuildParam `gorm:"foreignKey:BuildID" json:"params"`
  IsInvalid   bool         `gorm:"not null;default:false" json:"isInvalid"` 
+ TestResultSummaries []TestResultSummary `gorm:"foreignKey:BuildID" json:"testResultSummaries"`
}

+type TestResultSummary struct {
+  ArtifactID  uint      `gorm:"not null;index:testresultsummary_idx_artifact_id" json:"artifactId"`
+  Artifact    *Artifact `gorm:"foreignKey:ArtifactID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
+  BuildID     uint      `gorm:"not null;index:testresultsummary_idx_build_id" json:"buildId"`
+  Build       *Build    `gorm:"foreignKey:BuildID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
+  Total       uint      `gorm:"not null" json:"total"`
+  Failed      uint      `gorm:"not null" json:"failed"`
+  Passed      uint      `gorm:"not null" json:"passed"`
+  Skipped     uint      `gorm:"not null" json:"skipped"`
+}

+type TestResult struct {
+  ArtifactID  uint              `gorm:"not null;index:testresult_idx_artifact_id" json:"artifactId"`
+  Artifact    *Artifact         `gorm:"foreignKey:ArtifactID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
+  Name        string	        `gorm:"not null" json:"name"`
+  Message     string            `gorm:"nullable" json:"message"`
+  StartedOn   *time.Time        `gorm:"nullable;default:NULL;" json:"startedOn" format:"date-time"`
+  CompletedOn *time.Time        `gorm:"nullable;default:NULL;" json:"finishedOn" format:"date-time"`
+  Status      TestResultStatus  `gorm:"not null" enums:"Failed,Passed,Skipped"`
+}
```
```go
// artifact.go
// new
type File struct {
  name string
  fileName string
  data []bytes
}
// new, /build/{buildid}/test-results
func (m ArtifactModule) putTestResultsHandler(c *gin.Context) {
  // parseMultipartFormData to get the files
  // for each file, parse and store in db
}
// new, /build/{buildid}/artifact/{artifactid}/test-results
func (m ArtifactModule) getBuildArtifactTestResultsHandler(c *gin.Context) {
  // fetch test results for the specified test
}
// new
func parseMultipartFormData(c *gin.Context) []*File {
  // ...
}
// new
func parseTRX(file *File) []TestResult, TestResultSummary {
  // ...
}
```

The new endpoint `GET /build/{buildid}/test-results-summary` fetches
all test result summaries for a build and constructs a json response
that contains them, and has a summary of them, like:

<details><summary>GET /build/42/test-results-summary</summary>

```json
{
  "failed": 4,
  "passed": 5,
  "skipped": 0,
  "artifacts": [
    {
      "artifactId": 123,
      "filename": "MyResults1.trx",
      "failed": 1,
      "passed": 3,
      "skipped": 0
    },
    {
      "artifactId": 124,
      "filename": "MyResults2.trx",
      "failed": 3,
      "passed": 2,
      "skipped": 0
    }
  ]
}
```
</details>

### wharf-web

wharf-web changes to use the new endpoints
- `GET /build/{buildid}/test-results-summary`\
  To get summary of all test result summaries for build.
  
- `GET /build/{buildid}/artifact/{artifactid}/test-results`\
  To get test result details for build.
  
- `POST /build/{buildid}/test-results`\
  To upload test result files for build.

Deprecated endpoint
- `GET /build/{buildid}/tests-results`

There would also be a way to view a build's test results' details. [#17](https://github.com/iver-wharf/wharf-api/issues/17)

## Compatibility

Nothing comes to mind.

## Alternative solutions

Nothing comes to mind.

## Future possibilities

Nothing comes to mind.

## Unresolved questions

Nothing comes to mind.

## Resolved questions

- I am having trouble thinking of how to test filling out the database
  with data from the old test results. **What would be a good way to do this?**
  - We can ignore this. There's not much to gain from this.
  
- **Is an upload endpoint, separate from the one for other artifacts, for test
  results necessary?**
  I can see it being necessary if somebody wants to upload local test results
  or something, but it doesn't feel like that would be required. ref. to: [Create a separate method to upload test results apart from artifacts](https://github.com/iver-wharf/wharf-api/issues/11)
  - Yes. Separating responsibilities into separate endpoints allows the existing
    endpoint to remain "dumb", while at the same time allowing us to expand the
    functionality of the new endpoint with flags/logic.

- As mentioned in [#17](https://github.com/iver-wharf/wharf-api/issues/17), we
  are unlikely to have to store successful test details.
  **Is there any foreseeable drawback to going that route?**
  - Yes. It can be good to store successful tests to, for example, notice performance
  regression. Seeing which tests have been skipped can also be good to determine
    whether they have been skipped by mistake or not.