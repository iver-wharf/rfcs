---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 0 # Update this with PR number/ID. No leading zeros
rfc_feature_name: Go modules # Use kebab-case
title: "RFC-0000: Go modules" # Update this with PR number/ID and feature name. Use leading zeros
rfc_author_username: jilleJr
rfc_author_name: Kalle Fagerberg # Or same as username, if you wish

# Leave these. Collaborator changes this before merging
impl_issue_id: 0
impl_issue_repo: iver-wharf/wharf-api
last_modified_date: YYYY-MM-DD
---

# {{page.title}}

- RFC PR: [iver-wharf/rfcs#{{page.pr_id}}](https://github.com/iver-wharf/rfcs/pull/{{page.pr_id}})
- Feature name: `{{page.rfc_feature_name}}`
- Author: {{page.rfc_author_name}} ([@{{page.rfc_author_username}}](https://github.com/{{page.rfc_author_username}}))
- Implementation issue: [{{page.impl_issue_repo}}#{{page.impl_issue_id}}](https://github.com/{{page.impl_issue_repo}}/issues/{{page.impl_issue_id}})
- Implementation status: ![GitHub issue state](https://img.shields.io/github/issues/detail/state/{{page.impl_issue_repo}}/{{page.impl_issue_id}}?{{page.shields_io_query_params}})

## Summary

Max one paragraph long description to fill in context and overview of this RFC.

<!--
   Try to fill out the following sections. If nothing comes to mind for a
   section, then literally write "Nothing comes to mind".

   You are welcome to add more sections if you so need to.
-->

## Motivation

Why do we need this? What's the problem you are trying to solve?

## Explanation

Explain it as if you're writing documentation for an already existing feature.
This is where you would add code samples, such as:

```go
type MyType struct {
    text   string
    number int
}

func (mt MyType) String() string {
    return fmt.Sprintf("%q %d", mt.text, mt.number)
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
