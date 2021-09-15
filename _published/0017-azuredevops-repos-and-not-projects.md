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
impl_issue_id: 30
impl_issue_repo: iver-wharf/wharf-provider-azuredevops
last_modified_date: 2021-10-02
---

# {{page.title}}

- RFC PR: [iver-wharf/rfcs#{{page.pr_id}}](https://github.com/iver-wharf/rfcs/pull/{{page.pr_id}})
- Feature name: `{{page.rfc_feature_name}}`
- Author: {{page.rfc_author_name}} ([@{{page.rfc_author_username}}](https://github.com/{{page.rfc_author_username}}))
- Implementation issue: [{{page.impl_issue_repo}}#{{page.impl_issue_id}}](https://github.com/{{page.impl_issue_repo}}/issues/{{page.impl_issue_id}})
- Implementation status: ![GitHub issue state](https://img.shields.io/github/issues/detail/state/{{page.impl_issue_repo}}/{{page.impl_issue_id}}?{{page.shields_io_query_params}})

## Summary

Resolving two birds with one RFC here:

1. We're importing each Azure DevOps project as its own Wharf project, while a
   project in Azure DevOps may contain more than one Git repositories. To Wharf,
   these repositories should be treated as distinct Wharf projects.

2. When importing Azure DevOps projects from <https://dev.azure.com/>, the Git
   SSH URL is assigned an invalid value, as reported over in
   [Invalid gitURL when importing from https://dev.azure.com (wharf-provider-azuredevops#24)](https://github.com/iver-wharf/wharf-provider-azuredevops/issues/24).

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

When importing an Azure DevOps project, the Wharf group and project names use
the following format:

|         | Wharf project group           | Wharf project name |
| ------- | -------------------           | ------------------ |
| Format  | `{azure-org}/{azure-project}` | `{azure-repo}`     |
| Example | MyOrg/MyProject               | MyRepo             |

Where:

- `{azure-org}` = name of the Azure DevOps organization that holds the Azure
  DevOps project.

- `{azure-project}` = name of the Azure DevOps project.

- `{azure-repo}` = name of the code repository inside the Azure DevOps project.

Wharf projects that has been imported in earlier versions may need an automatic
rename on their next import. To see how this is handled in detail, see the
[#Renaming projects](#renaming-projects) section.

### Import procedure

1. First get the Azure DevOps project(s) using the endpoint:

   ```http
   GET https://dev.azure.com/{organization}/_apis/projects
   ```

   <https://docs.microsoft.com/en-us/rest/api/azure/devops/core/projects/list?view=azure-devops-rest-5.0>

   This is used to get the following information:

   - Project name
   - Project description
   - Project ID (GUID)

2. For every project, list the code repositories to import using the endpoint:

   ```http
   GET https://dev.azure.com/{organization}/{projectId}/_apis/git/repositories
   ```

   <https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/list?view=azure-devops-rest-5.0>

   This is used to get the following information:

   - Repository name
   - Git SSH URL
   - Default branch name (but make sure to trim away the `refs/heads/` prefix)

3. For every code repository, list the branches to import using the endpoint:

   ```http
   GET https://dev.azure.com/{organization}/_apis/git/repositories/{repositoryId}/refs?filter=heads/
   ```

   <https://docs.microsoft.com/en-us/rest/api/azure/devops/git/refs/list#refs-heads>

   This is used to get the following information:

   - Branch name (but make sure to trim away the `refs/heads/` prefix)

## Compatibility

### Keeping compatibility with self-hosted instances

Will be kept. Compared to v1, we will use 1 new endpoint:

```http
GET https://dev.azure.com/{organization}/{projectId}/_apis/git/repositories
```

This new endpoint does also exist in Azure DevOps API v5.0, which we have
relied on up until now.

As for the new procedure of getting the Git SSH URL, this will produce better
stability than before for unconventional installations of self-hosted
Azure DevOps instances as long as their Git SSH URL is configured correctly,
whereas conventional installations will continue to behave as before.

### Renaming projects

Due to the Wharf project name change we will have to add backward
compatibility to find these projects when importing with the new version
and automatically rename them. Something like:

1. Try find Wharf project according rules defined in
   [#Wharf project naming](#wharf-project-naming).

   If there are more than 1 code repository, try with
   `group="{azure-org}" && name="{azure-project}"`, as that was the old
   behavior from wharf-provider-azuredevops v1.

2. Update Wharf project with fresh data, including the new group name and
   project name.

We need to get through the ["group name cannot be changed"](https://github.com/iver-wharf/wharf-api/blob/74a4718fa830413a7e03cc5efed4d56f08f0398d/project.go#L365-L375)
validation criteria. As the validation is arbitrary it will be removed.
This would also resolve the inconsistency that the validation is not checked in
the `POST /project` endpoint.

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

### Keeping with importing projects 1:1

For the sake of resolving
[Invalid gitURL when importing from https://dev.azure.com (wharf-provider-azuredevops#24)](https://github.com/iver-wharf/wharf-provider-azuredevops/issues/24)
we could settle with still importing 1 Wharf project per Azure DevOps project,
but this is so tightly coupled so it's best to tackle this inconsistency here
and now. This RFC is not meant to fix that bug, but instead designed so that
bug is fixed as a consequence.

### Different naming formats

There are three main naming styles:

| ID  | Project group                 | Project name     |
| --- | -------------                 | ------------     |
| A   | `{azure-org}/{azure-project}` |`{azure-repo}`    |
| B   | `{azure-org}`                 |`{azure-repo}`    |
| C   | `{azure-org}`                 |`{azure-project}` |

> Where:
>
> - `{azure-org}` = name of the Azure DevOps organization that holds the Azure
>   DevOps project.
>
> - `{azure-project}` = name of the Azure DevOps project.
>
> - `{azure-repo}` = name of the code repository inside the Azure DevOps
>   project.

The latter, naming C, is used in wharf-provider-azuredevops v1. For v2, how
do we handle the naming when there are more than 1 code repository?

1. Always use the naming A.

2. Use the naming C, unless the Azure DevOps project contains more than 1
   code repository, where naming A should be used instead.

3. Use the naming B/C when the `{azure-repo}` = `{azure-project}`, and use
   naming A otherwise.

Option 1 has been chosen based on the following values:

- Wharf group and project names will stay consistent. While there may be some
  duplication of phrasing in code repositories that share the same name as the
  Azure DevOps project, it will be easier for end-users to understand the
  connection if all Azure DevOps projects are imported the same way.

- Less volatile to change. While option 2 and 3 would result in format change
  whenever a project gains another code repository or the code repository is
  renamed, option 1 will stay the same. Before we tackle
  [Map projects per ID: update importers code (wharf-provider-azuredevops#6)](https://github.com/iver-wharf/wharf-provider-azuredevops/issues/6)
  sticking to option 1 will prove less bug prone.

## Future possibilities

- We can update the README.md inside wharf-provider-azuredevops :)

  ```diff
  -Import Wharf projects from Azure DevOps repositories. Mainly focused on
  -importing from self hosted Azure DevOps instances, importing from
  -dev.azure.com is not well tested.
  +Import Wharf projects from Azure DevOps repositories. Tested on importing
  +both from self hosted Azure DevOps instances as well as from <dev.azure.com>.
  ```

- For this issue: [Map projects per ID: update importers code (wharf-provider-azuredevops#6)](https://github.com/iver-wharf/wharf-provider-azuredevops/issues/6)
  we can import based on the Azure DevOps repository's GUIDs instead of the
  project GUIDs, which would be more accurate and would mean less backward
  compatibility migrations for the future, as this "importing repos and not
  projects" change seems inevitable anyway.

## Unresolved questions

- How to handle the naming?

  Has been resolved: [#Different naming formats](#different-naming-formats)
