---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 0 # Update this with PR number/ID. No leading zeros
rfc_feature_name: repo-labels # Use kebab-case
title: "RFC-0000: Repo labels" # Update this with PR number/ID and feature name. Use leading zeros
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

We are currently using mostly "vanilla GitHub" labels. This restricts us in our
way to quickly convey the categories of issues and PRs, as well as our lack of
prioritization makes it really tough to understand what is important.

## Motivation

We lack any form of prioritization in our GitHub issues, as well as more
fine grained labels to categorize our work in other than just `enhancement`.

## Explanation

We prioritize with one of four labels, all prefixed with `p/` as an
abbreviation of `priority/`:

| Label    | Description                                          |
| -----    | -----------                                          |
| `p/crit` | Critical priority. "Drop everything to work on this" |
| `p/high` | High priority. "Must have"                           |
| `p/med`  | Medium priority. "Good to have"                      |
| `p/low`  | Low priority. "Nice to have"                         |

We categorize with one of TODO labels, all prefixed with `t/` as an
abbreviation of `type/`:

<!-- lint disable maximum-line-length -->

| Label        | Description                                          | Former label name |
| -----        | -----------                                          | ----------------- |
| `t/feature`  | New feature or request                               | `enhancement`     |
| `t/bug`      | Something isn't working                              | `bug`             |
| `t/docs`     | Improvements or additions to documentation           | `documentation`   |
| `t/deps`     | Pull requests that update a dependency file          | `dependencies`    |
| `t/question` | Further information is requested                     | `question`        |
| `t/release`  | New release for this repo                            | `release`         |
| `t/chore`    | Refactoring or other changes not affecting end-users |                   |
| `t/meta`     | Meta-issue: issue that manages other issues          |                   |

<!-- lint enable maximum-line-length -->

Some of the above are renamed labels from what GitHub provides by default. The
original GitHub-provided label names are found in the "Former label name"
column.

## Compatibility

There are some GitHub-provided labels that are left as-is, as they explain the
state of an issue or PR instead of describing its content. Some of these are
also highly conventional, such as the `good first issue` label which some users
use as a search term when searching for GitHub repositories to contribute to.
For consistency, all are left unchanged.

| Label              | Description                               |
| -----              | -----------                               |
| `duplicate`        | This issue or pull request already exists |
| `good first issue` | Good for newcomers                        |
| `help wanted`      | Extra attention is needed                 |
| `invalid`          | This doesn't seem right                   |
| `wontfix`          | This will not be worked on                |

One other label that needs extra attention is the `dependencies` label used by
Dependabot. Dependabot can be configured on a dependency version bump PR by
changing the labels used in the PR to `t/deps` and then commenting
`@dependabot use these labels`. This will be resolved in a retroactive fashion.

## Alternative solutions

- Not using label prefixes: The label prefixes groups the different label types
  and gives a better insinuation to the PR/issue author that there should be
  at least one from those categories.

- Longer label prefixes: Could use full `priority/high`, but this creates
  overly long labels that take up a lot of space in the issue list.

- GitHub projects beta: The new GitHub projects supports adding arbitrary
  metadata to issues and PRs. One use case of this is to add an integer
  priority. This could work as well, however it's still in beta and is lacking
  some automation and integration features. Moving from label-based
  prioritization over to GitHub Projects integer prioritization later should
  not be that difficult.

## Future possibilities

We can later add automation via GitHub actions or Wharf to try enforce at least
one of `t/*` and `p/*` label types are applied to issues.

## Unresolved questions

- "Estimated work size" labels? Such as having:

  | Label        | Description                               |
  | -----        | -----------                               |
  | `s/epic`     | Estimated to span longer than 1 sprint
  | `s/large`    | Estimated to fit 1 large-sized in 1 sprint
  | `s/medium`   | Estimated to fit 2-3 medium-sized in 1 sprint
  | `s/small`    | Estimated to fit 4 or more small-sized in 1 sprint

  Yay/nay?
