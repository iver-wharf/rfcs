---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 8 # Update this with PR number/ID. No leading zeros
rfc_id: 0008 # Update this with PR number/ID. Use leading zeros
rfc_feature_name: codacy # Use kebab-case
title: "RFC-0008: codacy"
rfc_author_username: jilleJr
rfc_author_name: Kalle Jillheden # Or same as username, if you wish

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

Introducing static code checks and code quality checks using [Codacy](https://www.codacy.com/).

## Motivation

Automated code reviews are super helpful as it removes a lot of the nit-picky
discussions from code reviews as well as catches far more small mistakes.

Codacy is a great platform that is free for open source projects and is a
collection of a wide range of code analysis tools.

## Explanation

Our Codacy organization will be found over at <https://app.codacy.com/gh/iver-wharf>
where all of our projects has been added.

We aim to use the same quality settings and code patterns throughout all of our
repositories, so most of our linting configuration will be placed as config
files inside the repositories, such as the `.remarkrc` files.

### Quality settings

Codacy allows setting quality settings for how it declares commits to be OK or
rejected. A rejected commit will block a pull request.

- Reject commits when...

  - *(keep default values)*

- Reject pull requests when...

  - *(keep default values, except:)*
  - Duplication is over `1` cloned block(s)

- Repository is considered unhealthy when...

  - *(keep default values)*

Read more: <https://docs.codacy.com/repositories-configure/quality-settings/>

### Integration

GitHub integration settings:

- Status checks: ON
- Annotations: OFF
- Summary: ON *(non-default)*
- Suggested fixes: ON *(non-default)*

Read more: <https://docs.codacy.com/repositories-configure/integrations/github-integration/#configuring-the-github-integration>

### Code patterns

- Revive (<https://revive.run/>), Go linter
- RemarkLint (<https://github.com/remarkjs/remark-lint>), Markdown linter
- ESLint (<https://eslint.org/>), JavaScript & TypeScript linter
- Stylelint (<https://stylelint.io/>), LESS, SASS, & CSS linter
- Hadolint (<https://github.com/hadolint/hadolint/>), Dockerfile linter

As for configuration, we have RemarkLint (`.remarkrc`) and
ESLint (`.eslintrc.json`) config files already in the repositories. None yet
for Revive, but that is left as-is to use the default settings.

Read more: <https://docs.codacy.com/repositories-configure/code-patterns/#using-your-own-tool-configuration-files>

## Compatibility

Nothing comes to mind.

## Alternative solutions

Using Codeac (<https://www.codeac.io/>) instead of Codacy (<https://www.codacy.com/>)

Here it falls in more with previous experience. I (@jilleJr) have a bias
towards Codacy as I've used it before and find it very capable. I have not
tried Codeac, although its popularity is steadily rising, but we can always
transition away from Codacy over to Codeac later on if we so wish.

## Future possibilities

Nothing comes to mind.

## Unresolved questions

Nothing comes to mind.
