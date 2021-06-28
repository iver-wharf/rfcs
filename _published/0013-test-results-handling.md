---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 13 # Update this with PR number/ID. No leading zeros
rfc_feature_name: rework-handling-of-test-results # Use kebab-case
title: "RFC-0013: rework-handling-of-test-results" # Update this with PR number/ID and feature name. Use leading zeros
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

The intent is to avoid filtering and parsing test result files (TRX) from the generated artifacts
each time we want to display them or a summary. In wharf-web's project view, the Status field
for builds (Failed/Completed) currently does this for each build every time it's refreshed to
display the outcome, leading to unnecessary requests and computation.

## Motivation

This is bad for the user because it leads to slower response times when loading the project view.
It's also bad for the API because it leads to unnecessary DB fetches, and pointless repeated computation.

## Explanation

The /build/{buildid}/artifact endpoint handles separating TRX (XML) files from other artifacts, and parses
them to create an array of `TestResult`, and one `TestResultSummary` per request.

The summaries get inserted into the database table `test_result_summary`.
The results get inserted into the database table `test_result`.

IMAGE
<!--
insert wharf-db.png here
-->

Explain it as if you're writing documentation for an already existing feature.
This is where you would add code samples, such as:

```go
// More pseudocode than not, especially ignoring error-handling.
type TestResult struct {
    BuildID uint
    Name string
    Ran bool
    Passed bool
    StartedOn time.Time
    EndedOn time.Time
}

type TestResultSummary struct {
	BuildID uint
	RanCount uint
	SkippedCount uint
	FailedCount uint
	PassedCount uint
}

type File struct {
    name string
    fileName string
    data []bytes
}

func (m ArtifactModule) postBuildArtifactHandler(c *gin.Context) {
	files := readMultipartForm(c) // returns []File
	// buildId := ginutil.ParseParamUint(c, "buildid")

	for _, file := range files {
		if strings.HasSuffix(file.fileName, ".trx") {
			parseTRXAndStoreInDB(file, buildID)
		} else {
			storeArtifactInDB(file, buildID)
		}
	}
}

func parseTRXAndStoreInDB(file File, buildID uint) {
	testResults, testSummary := parseTRX(file) 
	// foreach t testResults -> t.BuildID = buildID 
	testSummary.BuildID = buildID
	
	m.Database.CreateInBatch(&testResults)
	m.Database.Create(&testSummary)
}

func storeArtifactInDB(file File, buildID uint) {
	m.Database.Create(&Artifact{
		Data: file.data, 
		Name: file.name, 
		FileName: file.fileName, 
		BuildID: buildID,
	})
}
```

## Compatibility

Bring up compatibility issues and other things to regard. How will this
interfere with existing components (providers, database, frontend)? Does this
break backward compatibility?

## Alternative solutions

You pronounce one solution in this RFC, but keep the other alternatives you can
think about in here.

## Future possibilities

Does this lay groundwork for some future changes? If so, what?

## Unresolved questions

Questions you \[RFC author] want help resolving from the reviewers.
