---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 26 # Update this with PR number/ID. No leading zeros
rfc_feature_name: v2-go-modules-release # Use kebab-case
title: "RFC-0026: v2+ Go modules release" # Update this with PR number/ID and feature name. Use leading zeros
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

Go modules, which is the package management strategy we use in Wharf, has
strict rules on how to publish v2+ releases. We have not been Go-modules
compliant in some of our repositories. This RFC suggest one of the many
alternative solutions for being compliant, with its up- and downsides.
This is an important decision, as it induces a lot of headaches if we do it
wrong and have to choose a different strategy.

> There's an ironic trivia fact here: The documentation for Go modules is
> longer than the full [Go language specification](https://go.dev/ref/spec),
> but worse is that the Go modules resources are spread out across blog posts,
> wiki's, and documentation sites.

This is based on a conversation that popped up in a PR comment thread:
<https://github.com/iver-wharf/wharf-api-client-go/pull/29#discussion_r766513730>

## Motivation

The wharf-api is an example of a version 2 or higher Go module we've release.
Trying to import packages from for example v4.2.0 results in an error:

```console
$ go get github.com/iver-wharf/wharf-api/pkg/orderby@v4.2.0
go get github.com/iver-wharf/wharf-api/pkg/orderby@v4.2.0:
  github.com/iver-wharf/wharf-api@v4.2.0:
    invalid version:
      module contains a go.mod file, so major version must be compatible:
        should be v0 or v1, not v4
```

*(I've wrapped the above console output just to be more readable)*

## Explanation

We release new major versions by updating the module path in `go.mod` and all
related imports in `*.go` files.

Example:

```diff
-module github.com/iver-wharf/wharf-api
+module github.com/iver-wharf/wharf-api/v5

 go 1.16
```

```diff
 package main

 import (
-    "github.com/iver-wharf/wharf-api/pkg/model/database"
+    "github.com/iver-wharf/wharf-api/v5/pkg/model/database"
 )
```

### Counter-recommendation decisions

Contrary to some of the official Go recommendations, we do not apply any of the
following strategy:

- :warning: No duplicating code into subdirectories, where v1 would be kept at
  `<repo root>/` and v2 would be kept at `<repo root>/v2/`. This breaks
  compatibility with Go versions older than 1.9.7, 1.10.3, and 1.11.0.

- :warning: No separate branches for different major versions. All code will
  target and live on the `master` branch in each repository. This breaks
  compatibility with Go versions older than 1.11.0 and projects using
  [vendoring](https://go.dev/ref/mod#vendoring) and/or GOPATH modes.

- :warning: No support for older major versions. When we release a new major
  version, we deprecate the previous one and make no promises on maintaining it
  through bug fixes, patches, or any other changes.

- :warning: No intended support for GOPATH due to the above statements. Wharf's
  library modules makes no promises in staying compatible with GOPATH packaging
  strategies. This is an intentional decision to reduce complexity on our end.

### Go version compatibility

We focus on keeping compatibility with whatever version we have defined in our
`go.mod` files. At the time of writing, that is Go v1.16.

Supporting Go versions older than 1.11 is not in our interest.

### References

The above decisions has been made from researching the following pages:

- <https://github.com/golang/go/wiki/Modules#releasing-modules-v2-or-higher>
- <https://go.dev/blog/v2-go-modules#major-version-strategies>
- <https://go.dev/doc/modules/release-workflow#breaking>
- <https://go.dev/doc/modules/major-version>

## Compatibility

This breaks compatibility with developers using vendoring (where copies of the
dependency source code is stored in `<repo root>/vendor/...`) and/or GOPATH
(where source code you're working on is kept in `$GOPATH/src/...`, eg.
`~/src/...`).

These are considered deprecated packaging strategies. While there are many
projects out there still relying on these strategies, it's nothing we at Wharf
currently use, and more importantly it's nothing that we want to spend time on
supporting.

Instead we focus on solely supporting Go modules (where dependency source code
is stored in distinct directories depending on version inside
`$GOPATH/pkg/mod/...`, eg.  `~/go/pkg/mod/...`)

The core product is the Wharf platform and not the suite of libraries, and we
focus our compatibility accordingly.

## Alternative solutions

As listed in the [#Explanation](#explanation) section, there are numerous
counter-recommendation-oriented decisions made here. However most of these
recommended strategies are focused on supporting older Go versions, but as our
`go.mod` is defined to only supporting v1.16 and higher, this argument falls
apart.

Here's a rundown for the motivation for each of the decisions:

- **No duplicating code into subdirectories:** While seemingly simple, it does
  introduce a lot of code duplication which is there solely for allowing us to
  maintain multiple versions of a library at the same time. This is encouraged
  by Go as it's the most backward compatible solution with the old GOPATH and
  package vendoring solutions.

- **No separate branches:** Great Git-flow methodologies that is impractical in
  our current team. It adds complexity (which is needed to coordinate larger
  teams), but said complexity is expected to mostly be a hindrance in our case.

- **No support for older major versions:** This is touched on in above two
  bullet points. Distinct version-branches or subdirectories are also great for
  maintaining multiple versions. But this is something we have no intention of
  doing right now for Wharf. While we focus on keeping backward compatibility
  for at least a few versions, we do not spend time on patching or backporting
  changes to older major versions.

- **No intended support for GOPATH:** As stated in the
  [#Compatibility](#compatibility) section above, we consider GOPATH and package
  vendoring to be a relic of the past that we do not want to spend time on.

## Future possibilities

- The potential version 2 release of other Wharf library modules, such as
  wharf-core, should use the same strategy as outlined in this RFC's
  [#Explanation](#explanation).

## Unresolved questions

Nothing comes to mind.
