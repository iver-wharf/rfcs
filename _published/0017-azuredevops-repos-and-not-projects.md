---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 17 # Update this with PR number/ID. No leading zeros
rfc_feature_name: azuredevops-repos-and-not-projects # Use kebab-case
title: "RFC-0017: azuredevops-repos-and-not-projects" # Update this with PR number/ID and feature name. Use leading zeros
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

Max one paragraph long description to fill in context and overview of this RFC.

<!--
   Try to fill out the following sections. If nothing comes to mind for a
   section, then literally write "Nothing comes to mind".

   You are welcome to add more sections if you so need to.
-->

1. We're importing each Azure DevOps project as its own Wharf project, while a
   project in Azure DevOps may contain multiple Git repositories. To Wharf,
   these repositories should be treated as distinct Wharf projects.

2. When importing Azure DevOps projects from <https://dev.azure.com/>, the Git
   SSH URL is assigned an invalid value, as reported over in
   <https://github.com/iver-wharf/wharf-provider-azuredevops/issues/24>.

   This because we're importing projects and not the repositories so we don't
   get a Git SSH URL from the remote API and instead try to construct it on an
   inaccurate assumtion, as can be seen here:
   [github.com/iver-wharf/wharf-provider-azuredevops/blob/internal/importer/importer.go](https://github.com/iver-wharf/wharf-provider-azuredevops/blob/7b6397029b9bbe10e14e1367195e2491bd6eae83/internal/importer/importer.go#L274-L285)

## Motivation

Importing from Azure DevOps with the wharf-provider-azuredevops is glitchy
today. We rely on some assumed URL formats for the Git SSH URLs and we don't
support multi-repo projects.

This sprung up recently when a user of Wharf wanted to start importing from
<https://dev.azure.com/> where they previously only imported from self-hosted
instances. This is a critical user of Wharf, so the priority of this is raised
just thereof.

## Explanation

### Expected behaviour

When importing all for a given group (organization), first obtain the list of
Azure DevOps projects using:

> ```http
> GET https://dev.azure.com/{organization}/_apis/projects
> ```
>
> <https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.0>

Then, fetch the lists of repositories for each project by ID, or the specific
project by name when only importing one, by using the following endpoint:

> ```http
> GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories
> ```
>
> <https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/list?view=azure-devops-rest-5.0>

If the list of repositories for a given project is 2 or more, then import them
as the Wharf group name `{organization}/{project}` and the Wharf project name
as `{repository}`.

If the list of repositories for a given project is 1, then import that repo as
the Wharf group name `{organization}` and the Wharf project name as `{project}`

### Actual behaviour

When importing all projects for a group (organization):

> ```http
> GET https://dev.azure.com/{organization}/_apis/projects
> ```
>
> <https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.0>

When importing a single project by project name and group (organization) name:

> ```http
> GET https://dev.azure.com/{organization}/_apis/projects/{projectId}
> ```
>
> <https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/get?view=azure-devops-rest-5.0>

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
