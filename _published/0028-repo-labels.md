---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 28 # Update this with PR number/ID. No leading zeros
rfc_feature_name: repo-labels # Use kebab-case
title: "RFC-0028: Repo labels" # Update this with PR number/ID and feature name. Use leading zeros
rfc_author_username: jilleJr
rfc_author_name: Kalle Fagerberg # Or same as username, if you wish

# Leave these. Collaborator changes this before merging
impl_issue_id: 0
impl_issue_repo: iver-wharf/iver-wharf.github.io
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

### Issue/PR prioritization labels

Issues are prioritized via one of four labels, all prefixed with `prio/` as an
abbreviation of `priority/`:

| Label       | Description                                          |
| -----       | -----------                                          |
| `prio/crit` | Critical priority. "Drop everything to work on this" |
| `prio/high` | High priority. "Must have"                           |
| `prio/med`  | Medium priority. "Good to have"                      |
| `prio/low`  | Low priority. "Nice to have"                         |

### Issue/PR type labels

Issues or PRs has one the following types, which we categorize with one of
eight labels, all prefixed with `type/`:

<!-- lint disable maximum-line-length -->

| Label           | Description                                                    | Former label name |
| -----           | -----------                                                    | ----------------- |
| `type/feature`  | New feature or request                                         | `enhancement`     |
| `type/bug`      | Something isn't working                                        | `bug`             |
| `type/docs`     | Improvements or additions to documentation                     | `documentation`   |
| `type/deps`     | Pull requests that update a dependency file                    | `dependencies`    |
| `type/question` | Further information is requested                               | `question`        |
| `type/release`  | New release for this repo                                      | `release`         |
| `type/chore`    | Refactoring or other changes not affecting end-users           |                   |
| `type/meta`     | Meta-issue: issue that manages other issues                    |                   |
| `type/rfc`      | This issue or pull request contains a new Request For Comments | `rfc`             |

<!-- lint enable maximum-line-length -->

Some of the above are renamed labels from what GitHub provides by default or
labels we at Wharf has added in the past. These previous label names are found
in the "Former label name" column.

The `type/rfc` label only applies to the <https://github.com/iver-wharf/rfcs> repo.

### Issue/PR state labels

These labels explain the state of an issue or PR.

<!-- lint disable maximum-line-length -->

| Label                 | Description                               |
| -----                 | -----------                               |
| `duplicate`           | This issue or pull request already exists |
| `good first issue`    | Good for newcomers                        |
| `help wanted`         | Extra attention is needed                 |
| `invalid`             | This doesn't seem right                   |
| `wontfix`             | This will not be worked on                |
| `rfc based`           | Based on a Wharf RFC                      |

<!-- lint enable maximum-line-length -->

Only the last label, `rfc based`, is a non-vanilla GitHub label.

## Compatibility

One label that needs extra attention is the `dependencies` label used by
Dependabot. Dependabot can be configured on a dependency version bump PR by
changing the labels used in the PR to `type/deps` and then commenting
`@dependabot use these labels`. This will be resolved in a retroactive fashion
whenever Dependabot creates a new PR, and will not be attempted to be solved
in a proactive manner.

## Alternative solutions

- Not using label prefixes: The label prefixes groups the different label types
  and gives a better insinuation to the PR/issue author that there should be
  at least one from those categories.

- Longer label prefixes: Could use full `priority/high`, but this creates
  overly long labels that take up a lot of space in the issue list.

- Shorter label prefixes: Could use only `prio/high`, but this makes them harder
  to understand without their description. They should be self-explanatory.

- GitHub projects beta: The new GitHub projects supports adding arbitrary
  metadata to issues and PRs. One use case of this is to add an integer
  priority. This could work as well, however it's still in beta and is lacking
  some automation and integration features. Moving from label-based
  prioritization over to GitHub Projects integer prioritization later should
  not be that difficult.

## Future possibilities

We can later add automation via GitHub actions or Wharf to try enforce at least
one of `type/*` and `prio/*` label types are applied to issues.

## Unresolved questions

- "Estimated work size" labels? Such as having:

  | Label           | Description                               |
  | -----           | -----------                               |
  | `size/epic`     | Estimated to span longer than 1 sprint
  | `size/large`    | Estimated to fit 1 large-sized in 1 sprint
  | `size/medium`   | Estimated to fit 2-3 medium-sized in 1 sprint
  | `size/small`    | Estimated to fit 4 or more small-sized in 1 sprint

  Yay/nay?
