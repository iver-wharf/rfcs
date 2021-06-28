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
summary. In wharf-web's project view, the Status field for
builds (Failed/Completed) currently does this for each build every
time it's refreshed. This leads to unnecessary requests and computation.

We also want to display more detailed test result summaries in wharf-web.
For this we will need to also store the messages that the tests produce.
At the very least for failed tests.

## Motivation

This is bad for the user because it leads to slower response times when
loading the project view. It's also bad for the API because it leads to
unnecessary fetches, and pointless repeated computation.

Having the tests' error messages is pretty much a necessity when trying
to fix them.

## Related GitHub issues
- wharf-api [#11](https://github.com/iver-wharf/wharf-api/issues/11) [#17](https://github.com/iver-wharf/wharf-api/issues/17)
- wharf-web [#13](https://github.com/iver-wharf/wharf-web/issues/13)

## Explanation

<details><summary>wharf-api</summary>

The POST `/build/{buildid}/artifact` endpoint handles inserting artifacts.
If there are TRX (XML) files, it also parses them to create an array of `TestResult` and
one `TestResultSummary` per file.

The summaries get inserted into the database table `test_result_summary`.
The results get inserted into the database table `test_result`.

IMAGE wharf-db-graph.png HERE

Pseudocode-like, without error handling
```go
// database_models.go
// modified
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
    // added 
    TestResultSummaryCount uint `gorm:"not null" json:"testResultSummaryCount"`
}
// new
type TestResultSummary struct {
    ArtifactID  uint	  `gorm:"not null;index:testresultsummary_idx_artifact_id" json:"artifactId"`
    Artifact    *Artifact `gorm:"foreignKey:ArtifactID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
    BuildID     uint      `gorm:"not null;index:testresultsummary_idx_build_id" json:"buildId"`
    Build       *Build    `gorm:"foreignKey:BuildID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
    RunCount    uint	  `gorm:"not null" json:"runCount"`
    SkipCount   uint	  `gorm:"not null" json:"skipCount"`
    FailCount   uint	  `gorm:"not null" json:"failCount"`
    PassCount   uint	  `gorm:"not null" json:"passCount"`
}
// new
type TestResult struct {
    ArtifactID  uint 	  `gorm:"not null;index:testresult_idx_artifact_id" json:"artifactId"`
    Artifact    *Artifact `gorm:"foreignKey:ArtifactID;constraint:OnUpdate:RESTRICT,OnDelete:RESTRICT" json:"-"`
    Name        string	  `gorm:"not null;" json:"name"`
    Ran         string 	  `gorm:"not null;" json:"ran"`
    Passed      string 	  `gorm:"not null;" json:"passed"`
    StartedOn   *time.Time `gorm:"nullable;default:NULL;" json:"startedOn" format:"date-time"`
    CompletedOn *time.Time `gorm:"nullable;default:NULL;" json:"finishedOn" format:"date-time"`
}
```

```go
// artifact.go
// new
type File struct {
    name string
    fileName string
    data []bytes
}
// modified
func (m ArtifactModule) postBuildArtifactHandler(c *gin.Context) {
    files := parseMultipartFormData(c)
    buildId := ginutil.ParseParamUint(c, "buildid")
    
    for _, file := range files {
    	storeArtifactInDB(file, buildID)
    	if strings.HasSuffix(file.fileName, ".trx") {
    	    parseTRXAndStoreInDB(file, buildID, artifact.ArtifactID)
    	}
    }
}
// new, /build/{buildid}/artifact/{artifactid}/test-results
func (m ArtifactModule) getBuildArtifactTestResultsHandler(c *gin.Context) {
    buildId := ginutil.ParseParamUint(c, "buildid")
    artifactId := ginutil.ParseParamUint(c, "artifactid")

    struct TestResults {
    	Results     []TestResult `json:"results"`
    	ArtifactID  uint `json:"artifactId"`
    	Count       uint `json:"count"`
    }
    
    testResults := TestResults{}
	
    m.Database.
        Where(&TestResult{BuildID: buildId, ArtifactID: artifactId}).
        Find(&testSummaries.Summaries)
    
    if len(testResults.Results) > 0 {
    	testResults.Count = len(testResults.Results)
    	testResults.ArtifactID = artifactId
    } else {
    	// dbnotfound error
    	return
    }
    
    // 200 with testResults
}
// new
func parseTRXAndStoreInDB(file *File, buildID, artifactID uint) {
    testResults, testSummary := parseTRX(file)
    
    for _, testResult := range testResults {
    	testResult.ArtifactID = artifactID
    }
    testSummary.ArtifactID = artifactID
    testSummary.BuildID = buildId
    
    m.Database.Create(&testResults)
    m.Database.Create(&testSummary)
}
// new
func storeArtifactInDB(file *File, buildID uint) (*Artifact) {
    artifact := Artifact{
    	Data: file.data, 
    	Name: file.name, 
    	FileName: file.fileName, 
    	BuildID: buildID,
    }
    m.Database.Create(&artifact)
    
    return &artifact 
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

```go
// build.go
// new, /build/{buildid}/test-result-summaries
func (m BuildModule) getBuildTestResultSummariesHandler(c *gin.Context) {
    buildId := ginutil.ParseParamUint(c, "buildid")

    struct TestResultSummaries {
    	Summaries []TestResultSummary `json:"summaries"`
    	Count     uint                `json:"count"`
    }
    
    testSummaries := TestResultSummaries{}
    
    m.Database.
    	Where(&TestResultSummary{BuildID: buildId}).
    	Find(&testSummaries.Summaries)
    
    if len(testSummaries.Summaries) > 0 {
    	testResults.Count = len(testResults.Results)
    } else {
    	// dbnotfound error
    	return
    }
    
    // 200 with testSummaries
}
```

</details>

<details><summary>wharf-web</summary>

wharf-web changes to use the new GET
`/build/{buildid}/test-result-summaries` and GET `/build/{buildid}/artifact/{artifactid}/test-results`
endpoints to retrieve the test result data instead of using the existing
GET `/build/{buildid}/tests-results` endpoint.

There would also be a way to view a build's test result details. [#17](https://github.com/iver-wharf/wharf-api/issues/17)
</details>

## Compatibility

This breaks backward compatibility with projects using the
GET `build/{buildid}/tests-results` endpoint, since it will get removed.

## Alternative solutions

Nothing comes to mind.

## Future possibilities

Nothing comes to mind.

## Unresolved questions

- I am having trouble thinking of how to test filling out the database
  with data from the old test results. **What would be a good way to do this?**
  
- **Is an upload endpoint, separate from the one for other artifacts, for test
  results necessary?**
  I can see it being necessary if somebody wants to upload local test results
  or something, but it doesn't feel like that would be required. ref. to: [Create a separate method to upload test results apart from artifacts](https://github.com/iver-wharf/wharf-api/issues/11)

- As mentioned in [#17](https://github.com/iver-wharf/wharf-api/issues/17), we
  are unlikely to have to store successful test details.
  **Is there any foreseeable drawback to going that route?**