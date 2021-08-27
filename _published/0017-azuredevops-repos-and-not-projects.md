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
   section, then "Nothing comes to mind" should be written verbatim.

   You are welcome to add more sections if you so need to.
-->

1. We're importing each Azure DevOps project as its own Wharf project, while a
   project in Azure DevOps may contain more than one Git repositories. To Wharf,
   these repositories should be treated as distinct Wharf projects.

2. When importing Azure DevOps projects from <https://dev.azure.com/>, the Git
   SSH URL is assigned an invalid value, as reported over in
   <https://github.com/iver-wharf/wharf-provider-azuredevops/issues/24>.

   This because we're importing projects and not the repositories so we don't
   get a Git SSH URL from the remote API and instead try to construct it on an
   inaccurate assumption, as can be seen here:
   [github.com/iver-wharf/wharf-provider-azuredevops/blob/internal/importer/importer.go](https://github.com/iver-wharf/wharf-provider-azuredevops/blob/7b6397029b9bbe10e14e1367195e2491bd6eae83/internal/importer/importer.go#L274-L285)

## Motivation

Importing from Azure DevOps with the wharf-provider-azuredevops is glitchy
today. We rely on some assumed URL formats for the Git SSH URLs and we don't
support multi-repo projects.

This issue came up when a user of Wharf wanted to start importing from
<https://dev.azure.com/> where they before imported from self-hosted
instances. This is a critical user of Wharf, so the priority of this is raised
thereof.

## Explanation

### Definitions

#### Wharf project

A single project in Wharf contains

- list of builds
- reference to a single remote code repository (Git)

#### Azure DevOps project

A single project in Azure DevOps contains:

- issue tracking
- wiki
- CI/CD pipelines
- any number of code repositories (Git and/or TFVC)

### Previous behavior

When importing a Wharf project from Azure DevOps via wharf-provider-azuredevops,
each targeted Azure DevOps project was imported 1:1 into Wharf.

Wharf assumed the Azure DevOps project had 1 code repository, and would import
the Azure DevOps project as a single Wharf project even if said Azure DevOps
project had more than one or zero code repositories, with an assumed Git SSH
URL instead of using the Git SSH URL that the Azure DevOps API provides in its
`sshUrl` field on the [GitRepository](https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/list?view=azure-devops-server-rest-5.0#gitrepository)
response for the [repository endpoints](https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories?view=azure-devops-server-rest-5.0).

This behavior exists in wharf-provider-azuredevops in v1. Starting from v2,
this behavior is as explained below in this RFC.

### Import repositories, not projects

Each code repository is imported 1:1 into Wharf as distinct Wharf projects.
If an Azure DevOps project contains more than 1 code repository, then said
Azure DevOps project will in practice be imported the same number of times,
albeit with different names on the Wharf projects to differentiate between them.

### Wharf project naming



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

### Renaming projects

Due to the Wharf project name change we will have to add backward
compatibility to find these projects when importing with the new version
and automatically rename them. Something like:

1. Try find Wharf project with `group="{azure-org}/{azure-project}" && name="{azure-repo}"`

   If none, then try `group="{azure-org}" && name="{azure-project}"`

2. Update Wharf project with fresh data, including the new group name and
   project name.

We would have to get through the ["group name cannot be changed"](https://github.com/iver-wharf/wharf-api/blob/74a4718fa830413a7e03cc5efed4d56f08f0398d/project.go#L365-L375)
thing then, but that validation criteria seems arbitrary anyway and should be
removed. Cherry on top is that it's not even checked in the `POST /project`
endpoint.

### Build pipelines will fail

Builds that solely rely on the [`REPO_GROUP`](https://iver-wharf.github.io/#/usage-wharfyml/variables/built-in-variables?id=repo_group)
or [`REPO_NAME`](https://iver-wharf.github.io/#/usage-wharfyml/variables/built-in-variables?id=repo_name)
variables, either explicitly through variable substitution or implicitly such
as via the [`docker.group` or `docker.name`](https://iver-wharf.github.io/#/usage-wharfyml/step-types/docker)
(undocumented) defaults that use the same variables behind the scenes, will be
fine. Perhaps some Docker images are pushed to a new address, but as long as
that new registry address is writable and wherever that address is referenced
uses those above built-in variables then will work fine.

The issue is where users have hardcoded these URLs into their continuous
deployments. The Docker images will be pushed to a new location, but the old
location is still what's referenced, causing their builds to break.

This information needs to go out, preferably before this is released, to all
known users of wharf-provider-azuredevops telling them to start using
`${REPO_GROUP}` and `${REPO_NAME}` instead.

For the unknown users, we should try and word the CHANGELOG.md as clear as
possible declaring these impacts. We should also write a document on
<https://iver-wharf.github.io/> about upgrading wharf-provider-azuredevops from
v1 to v2, where we explain these backward incompatibilities as well.

## Alternative solutions

You pronounce one solution in this RFC, but keep the other alternatives you can
think about in here.

## Future possibilities

Does this lay groundwork for some future changes? If so, what?

## Unresolved questions

- How to handle the naming?

  There are three main naming styles:

  | ID  | Project group                 | Project name     |
  | --- | -------------                 | ------------     |
  | A   | `{azure-org}/{azure-project}` |`{azure-repo}`    |
  | B   | `{azure-org}`                 |`{azure-repo}`    |
  | C   | `{azure-org}`                 |`{azure-project}` |

  The latter, naming C, is used in wharf-provider-azuredevops v1. For v2, how
  do we handle the naming when there are more than 1 code repository?

  1. Always use the naming A.

  2. Use the naming C, unless the Azure DevOps project contains more than 1
     code repository, where naming A should be used instead.

  3. Use the naming B/C when the `{azure-repo}` = `{azure-project}`, and use
     naming A otherwise.
