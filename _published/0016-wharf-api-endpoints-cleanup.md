---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 16 # Update this with PR number/ID. No leading zeros
rfc_feature_name: wharf-api-endpoints-cleanup # Use kebab-case
title: "RFC-0016: wharf-api-endpoints-cleanup" # Update this with PR number/ID and feature name. Use leading zeros
rfc_author_username: jilleJr
rfc_author_name: Kalle Jillheden # Or same as username, if you wish

# Leave these. Collaborator changes this before merging
impl_issue_id: 65
impl_issue_repo: iver-wharf/wharf-api
last_modified_date: 2021-09-03
---

# {{page.title}}

- RFC PR: [iver-wharf/rfcs#{{page.pr_id}}](https://github.com/iver-wharf/rfcs/pull/{{page.pr_id}})
- Feature name: `{{page.rfc_feature_name}}`
- Author: {{page.rfc_author_name}} ([@{{page.rfc_author_username}}](https://github.com/{{page.rfc_author_username}}))
- Implementation issue: [{{page.impl_issue_repo}}#{{page.impl_issue_id}}](https://github.com/{{page.impl_issue_repo}}/issues/{{page.impl_issue_id}})
- Implementation status: ![GitHub issue state](https://img.shields.io/github/issues/detail/state/{{page.impl_issue_repo}}/{{page.impl_issue_id}}?{{page.shields_io_query_params}})

## Summary

Restructuring the wharf-api by changing the paths of the endpoints, adding and
renaming path parameters, and changing the request and response models around.

While we will keep backward compatibility for at least one major version, we
will be changing so much that this needs a full major version bump.

This is not the full list of changes to be made for v5. Instead, it's
a list of changes that will require us moving to it. Changes not listed in
this RFC may be included in the version bump as well.

## Motivation

We are lacking consistency in our API, and there are some questionable
endpoints in there. Most annoying issues are:

- Some endpoints are plural, some are singular.
  Ex: `POST /project` vs `GET /projects`.

- Some are misplaced and rely on request body instead of path/query
  parameters. Ex: `PUT /branches` instead of `PUT /project/{projectId}/branch`.

- Path parameters are all lowercased, while all other query parameters are
  camelCased.

- We use the database models in our HTTP request and response specs.
  The problems with this are:

  - Security weakness as it induces a higher risk of exposing too much data to
    the user.

  - Swagger documentation has room for improvement. We can elide irrelevant
    specifications such as allowing a project ID to be provided when creating
    a new project.

  - The abstraction layers get mixed. With different models we would decouple
    the HTTP layer from the database layer, allowing for easier customization
    in both layers, as well as easier to understand as the models doesn't have
    to worry both about how to serialize into JSON as well as their database
    table relations and constraints.

## Explanation

Moving from wharf-api v4 to v5, all endpoints are now in singular format.
Some have also been moved to a different subpath.

### RESTful API design

Starting with v5, all endpoints now follow a more strict RESTful approach.

Major changes:

- POST endpoints no longer acts as "add or update", but instead solely as
  "add".

- PUT endpoints no longer acts as "add or update", but instead solely as
  "update".

- POST endpoints for searching have been removed, please refer to the GET
  endpoints using query parameters instead of an HTTP request body to query.

  - This allows finer control over the search endpoints. Starting with v5, you
    now have a range of `{field}Match` query parameters that does a
    "soft match". Where, instead of trying to match the result verbatim, the
    API will try a fuzzy or partial search for better human search results.

- All endpoints without a path parameter declaring an ID are working with lists
  and not single items. Some endpoints have been changed between v4 and v5 to
  account for this, such as the `PUT /project -> PUT /project/{projectId}`
  endpoint change.

### Deprecation of endpoints

All endpoints that have been moved or removed are **still fully functioning
throughout the entire wharf-api v5**. The old endpoints has been **marked as
"Deprecated" in the Swagger/OpenAPI specification.**

A word of caution, the deprecated endpoints may be **removed in the next major
version bump up to v6.** As a user of the wharf-api, you need to migrate your
applications to use the new endpoints specified in this RFC.

### Request/response models changes

#### New subpackages for models

Starting with v5, the wharf-api no longer accepts nor returns database
models from **ANY** of its endpoints. Instead, there are now 3 new packages
of models inside the wharf-api:

- `/pkg/models/database`: Database models, with [GORM](https://gorm.io/)
  specific tags to declare table column names and SQL associations.

  These are the models from v4, though with any
  [JSON](https://pkg.go.dev/encoding/json#Marshal) or other specific tags
  trimmed away.

- `/pkg/models/request`: HTTP request models, sent by the client and received
  by the server. Go fields are tagged with:

  - [JSON](https://pkg.go.dev/encoding/json#Marshal) specific tags to declare
    how they will be serialized.

  - [Gin](https://gin-gonic.com/) specific tags such as which fields are
    required or optional, and sensible defaults.

  - [Swaggo](https://github.com/swaggo/swag) specific tags for better Swagger
    specification generation.

  There are some categories of request models for the same objects, namely:

  - "{Model}": Used in POST requests when creating new resources.

    Example:

    ```go
    package request

    type Provider struct {
        Name string `json:"name" binding:"required" validate:"required" example:"github" enums:"github,gitlab,azuredevops"`
        URL  string `json:"url" binding:"required" validate:"required" example:"https://api.github.com/"`
    }
    ```

  - "{Model}Update": Used in PUT requests when updating an existing resource.

    Example:

    ```go
    package request

    type ProviderUpdate struct {
        Name string `json:"name" binding:"required" validate:"required" example:"github" enums:"github,gitlab,azuredevops"`
        URL  string `json:"url" binding:"required" validate:"required" example:"https://api.github.com/"`
    }
    ```

- `/pkg/models/response`: HTTP response models sent by the server and received
  by the client. Go fields are tagged with:

  - [JSON](https://pkg.go.dev/encoding/json#Marshal) specific tags to declare
    how they will be serialized.

  - [Swaggo](https://github.com/swaggo/swag) specific tags for better Swagger
    specification generation.

  Example:

  ```go
  package response

  type Provider struct {
      ID   int    `json:"id" example:"123"`
      Name string `json:"name" example:"github" enums:"github,gitlab,azuredevops"`
      URL  string `json:"url" example:"https://api.github.com/"`
  }
  ```

Conversion between these are done explicitly on each usage to ensure no extra
values are leaked.

#### New layout for models

To reduce duplication in data and to make it more intuitive for the user,
endpoints now focus on the layout of the model instead of using
the database models.

Some overarching design principles going from v4 to v5:

- Do not rely on ID references in the HTTP request body when targeting a
  specific object. For example:

  - Good: `PUT /project/123`

    ```json
    {
      "name": "sample",
      "description": "Sample project"
    }
    ```

  - Bad: `PUT /project`

    ```json
    {
      "projectId": 123,
      "name": "sample",
      "description": "Sample project"
    }
    ```

- Do not use a model in the Swagger documentation that suggests the user can
  provide an object ID for endpoints that creates objects. For example:

  - Good: `POST /project`

    ```json
    {
      "name": "sample",
      "description": "Sample project"
    }
    ```

  - Bad: `POST /project`

    ```json
    {
      "projectId": 123,
      "name": "sample",
      "description": "Sample project"
    }
    ```

The PUT endpoints now follow these principles, e.g.
[`PUT /project/{projectId}/branch`](#put-projectprojectidbranch) (formerly
known as `PUT /branches`) and [`PUT /project/{projectId}`](#put-projectprojectid)
(formerly known as `PUT /project`) endpoints.

### Swagger/OpenAPI endpoint IDs

Starting with wharf-api v5, all endpoints now have IDs. These are ignored in
regular API usage, but when using code generation this comes in handy as the
endpoint IDs can be used for functions/methods instead of some auto-generated
names based on the path segments.

Where, in v4, the Swagger generated TypeScript method for
`POST /project/{projectId}/build` *(formerly known as
`POST /project/{projectid}/builds`)* was `projectProjectidBuildsGet()`, it will
now instead be `getProjectBranchList()`.

### Renamed path parameters

The path parameters have been changed from lowercase to camelCase.
This solely affects Swagger specification inspectors and code generators, such
as the [Swagger Codegen](https://github.com/swagger-api/swagger-codegen),
and has no implications on the APIs actual behavior.

Users who have autogenerated their clients and rely on the parameter names needs
to update their references slightly when moving from v4 to v5.

### `GET /build/{buildId}/artifact`

```diff
 Tag = artifact
+ID = getBuildArtifactList
-GET /build/{buildid}/artifacts
+GET /build/{buildId}/artifact
```

```diff
 NAME           PARAM    TYPE            REQUIRED?  DESCRIPTION
 buildId        (path)   integer         true
+limit          (query)  integer         false      Max number of items returned.
+offset         (query)  integer         false      Shifts the window returned.
+orderby        (query)  array[string]   false      Alphabetically, or order by ID?
+name           (query)  string          false      Filter on name hard match
+nameMatch      (query)  string          false      Filter on name soft match
+fileName       (query)  string          false      Filter on fileName hard match
+fileNameMatch  (query)  string          false      Filter on fileName soft match
```

### `POST /build/{buildId}/artifact`

```diff
 Tag = artifact
+ID = uploadBuildArtifact
-POST /build/{buildid}/artifact
+POST /build/{buildId}/artifact
```

### `GET /build/{buildId}/artifact/{artifactId}`

```diff
 Tag = artifact
+ID = getBuildArtifact
-GET /build/{buildid}/artifact/{artifactid}
+GET /build/{buildId}/artifact/{artifactId}
```

### `POST /build/search`

```diff
 Tag = artifact
-POST /build/search
```

- Deprecated. Please refer to the `GET /build` or
  `GET /project/{projectId}/build` instead.

### `GET /build`

```diff
+Tag = artifact
+GET /build
```

```diff
 NAME              PARAM    TYPE               REQUIRED?  DESCRIPTION
 buildId           (path)   integer            true
+limit             (query)  integer            false      Max number of items returned.
+offset            (query)  integer            false      Shifts the window returned.
+orderby           (query)  array[string]      false      Alphabetically, or order by ID?
+environment       (query)  string             false      Filter on environment hard match
+environmentMatch  (query)  string             false      Filter on environment soft match
+finishedAfter     (query)  string[date-time]  false      Filter on finishedOn
+finishedBefore    (query)  string[date-time]  false      Filter on finishedOn
+gitBranch         (query)  string             false      Filter on gitBranch hard match
+gitBranchMatch    (query)  string             false      Filter on gitBranch soft match
+isInvalid         (query)  boolean            false      Filter on isInvalid
+scheduledAfter    (query)  string[date-time]  false      Filter on scheduledOn
+scheduledBefore   (query)  string[date-time]  false      Filter on scheduledOn
+stage             (query)  string             false      Filter on stage hard match
+stageMatch        (query)  string             false      Filter on stage soft match
+status            (query)  string[enum]       false      Filter on status by enum string
+statusId          (query)  integer            false      Filter on status by ID
```

- New endpoint.

### `GET /build/{buildId}`

```diff
 Tag = build
+ID = getBuild
-GET /build/{buildid}
+GET /build/{buildId}
```

### `PUT /build/{buildId}`

```diff
 Tag = build
+ID = updateBuild
-PUT /build/{buildid}
+PUT /build/{buildId}
```

```diff
 NAME     PARAM    TYPE     REQUIRED?  DESCRIPTION
 buildId  (path)   integer  true       ID of build to update
-status   (query)  string   true       Build status term
```

```diff
 REQUEST BODY
+{
+  "status": string,
+}
```

### `GET /build/{buildId}/log`

```diff
 Tag = build
+ID = getBuildLogs
-GET /build/{buildid}/log
+GET /build/{buildId}/log
```

### `POST /build/{buildId}/log`

```diff
 Tag = build
+ID = createBuildLog
-POST /build/{buildid}/log
+POST /build/{buildId}/log
```

### `GET /build/{buildId}/stream`

```diff
 Tag = build
+ID = streamBuildLogs
-GET /build/{buildid}/stream
+GET /build/{buildId}/stream
```

### `GET /build/{buildId}/test-result`

```diff
-Tag = artifact
+Tag = build
+ID = getBuildTestResults
-GET /build/{buildid}/test-results
+GET /build/{buildId}/test-result
```

- Tag was changed. Plan is to decouple test results from artifacts, albeit in
  a series of different RFCs.

### `GET /health`

```diff
 Tag = health
+ID = getHealth
 GET /health
```

### `GET /ping`

```diff
 Tag = health
+ID = ping
 GET /ping
```

### `GET /version`

```diff
 Tag = meta
+ID = getVersion
 GET /version
```

### `GET /project`

```diff
 Tag = project
+ID = getProjectList
-GET /projects
+GET /project
```

```diff
 NAME                        PARAM    TYPE            REQUIRED?  DESCRIPTION
+limit               (query)  integer         false      Max number of items returned.
+offset              (query)  integer         false      Shifts the window returned.
+orderby             (query)  array[string]   false      Alphabetically, or order by ID?
+avatarUrl           (query)  string          false      Filter on avatarUrl hard match
+avatarUrlMatch      (query)  string          false      Filter on avatarUrl soft match
+defaultBranch       (query)  string          false      Filter on default branch hard match
+defaultBranchMatch  (query)  string          false      Filter on default branch soft match
+description         (query)  string          false      Filter on description hard match
+descriptionMatch    (query)  string          false      Filter on description soft match
+gitUrl              (query)  string          false      Filter on gitUrl hard match
+gitUrlMatch         (query)  string          false      Filter on gitUrl soft match
+groupName           (query)  string          false      Filter on groupName hard match
+groupNameMatch      (query)  string          false      Filter on groupName soft match
+name                (query)  string          false      Filter on name hard match
+nameMatch           (query)  string          false      Filter on name soft match
+providerId          (query)  string          false      Filter on provider by ID
```

### `POST /project`

```diff
 Tag = project
+ID = createProject
 POST /project
```

```diff
 REQUEST BODY
 {
   "avatarUrl": string,
   "defaultBranch": string,
   "branches": [
     {
-      "branchId": integer,
-      "default": boolean,
       "name": string,
-      "projectId": integer,
-      "tokenId": integer
     }
   ],
   "buildDefinition": string,
   "description": string,
   "gitUrl": string,
   "groupName": string,
   "name": string,
-  "projectId": integer,
-  "provider": {
-    "name": string,
-    "providerId": integer,
-    "tokenId": integer,
-    "uploadUrl": string,
-    "url": string
-  },
   "providerId": integer,
   "tokenId": integer
 }
```

- No longer an "add or update" endpoint, but instead solely an "add" endpoint.

### `POST /project/search`

```diff
 Tag = project
-POST /projects/search
```

- Deprecated. Please refer to the `GET /project` instead.

### `DELETE /project/{projectId}`

```diff
 Tag = project
+ID = deleteProject
-DELETE /project/{projectid}
+DELETE /project/{projectId}
```

### `GET /project/{projectId}`

```diff
 Tag = project
+ID = getProject
-GET /project/{projectid}
+GET /project/{projectId}
```

### `PUT /project/{projectId}`

```diff
 Tag = project
+ID = updateProject
-PUT /project
+PUT /project/{projectId}
```

```diff
 REQUEST BODY
 {
   "avatarUrl": string,
-  "branches": [
-    {
-      "branchId": integer,
-      "default": boolean,
-      "name": string,
-      "projectId": integer,
-      "tokenId": integer
-    }
-  ],
   "buildDefinition": string,
   "description": string,
   "gitUrl": string,
-  "groupName": string,
   "name": string,
-  "projectId": integer,
-  "providerId": integer,
-  "tokenId": integer
 }
```

- Added path parameter `{providerId}` for value that was taken from the HTTP
  request body.

- Most request body fields are removed as they are set through other endpoints
  (such as the [`PUT /project/{projectId}/branch`](#put-projectprojectidbranch))
  and some fields are not allowed to be changed such as `groupName`.

- This is no longer an "add or update" endpoint but instead solely an "update"
  endpoint.

### `GET /project/{projectId}/branch`

```diff
-Tag = branch
+Tag = project
+ID = getProjectBranchList
-GET /branches
+GET /project/{projectId}/branch
```

```diff
 NAME          PARAM    TYPE            REQUIRED?  DESCRIPTION
+limit         (query)  integer         false      Max number of items returned.
+offset        (query)  integer         false      Shifts the window returned.
+orderby       (query)  array[string]   false      Alphabetically, or order by ID?
+name          (query)  string          false      Filter on name hard match
+nameMatch     (query)  string          false      Filter on name soft match
+default       (query)  boolean         false      Filter on default
```

- Added path parameter `{providerId}` for value that was taken from the HTTP
  request body.

- This was not implemented before, but will be for v5. Goal is to remove the
  branch array from the project model by v6 and let users rely on this endpoint,
  as some projects may have thousands of branches.

### `POST /project/{projectId/branch`

```diff
-Tag = branch
+Tag = project
+ID = createProjectBranch
-POST /branch
+POST /project/{projectId}/branch
```

```diff
 NAME       PARAM   TYPE     REQUIRED?  DESCRIPTION
+projectId  (path)  integer  true       ID of project to add branch to.
```

```diff
 REQUEST BODY
 {
-  "branchId": integer,
   "default": boolean,
   "name": string,
-  "projectId": integer,
-  "tokenId": integer
 }
```

- Added path parameter `{providerId}` for value that was taken from the HTTP
  request body.

### `PUT /project/{projectId}/branch`

```diff
-Tag = branches
+Tag = project
+ID = updateProjectBranchList
-PUT /branches
+PUT /project/{projectId}/branch
```

```diff
 NAME       PARAM   TYPE     REQUIRED?  DESCRIPTION
+projectId  (path)  integer  true       ID of project to update branches for.
```

```diff
 REQUEST BODY
+{
+  "defaultBranch": string,
+  "branches":
   [
     {
-      "branchId": integer,
-      "default": boolean,
       "name": string,
-      "projectId": integer,
-      "tokenId": integer
     }
   ]
+}
```

- Added path parameter `{providerId}` for value that was taken from the HTTP
  request body.

### `GET /branch/{branchid}`

```diff
 Tag = project
-GET /branch/{branchid}
```

- Deprecated. Has not been moved, but instead planned to be removed.
  Was not implemented in v4, and its usage is replaced instead by the
  `GET /project/{projectId}/branch` endpoint.

### `GET /project/{projectId}/build`

```diff
 Tag = project
+ID = getProjectBuildList
-GET /project/{projectid}/builds
+GET /project/{projectId}/build
```

```diff
 NAME              PARAM    TYPE               REQUIRED?  DESCRIPTION
 projectId         (path)   integer            true
-limit             (query)  integer            true       Max number of items returned.
+limit             (query)  integer            false      Max number of items returned.
-offset            (query)  integer            true       Shifts the window returned.
+offset            (query)  integer            false      Shifts the window returned.
 orderby           (query)  array[string]      false      Alphabetically, or order by ID?
+environment       (query)  string             false      Filter on environment hard match
+environmentMatch  (query)  string             false      Filter on environment soft match
+finishedAfter     (query)  string[date-time]  false      Filter on finishedOn
+finishedBefore    (query)  string[date-time]  false      Filter on finishedOn
+gitBranch         (query)  string             false      Filter on gitBranch hard match
+gitBranchMatch    (query)  string             false      Filter on gitBranch soft match
+isInvalid         (query)  boolean            false      Filter on isInvalid
+scheduledAfter    (query)  string[date-time]  false      Filter on scheduledOn
+scheduledBefore   (query)  string[date-time]  false      Filter on scheduledOn
+stage             (query)  string             false      Filter on stage hard match
+stageMatch        (query)  string             false      Filter on stage soft match
+status            (query)  string[enum]       false      Filter on status by enum string
+statusId          (query)  integer            false      Filter on status by ID
```

### `POST /project/{projectId}/build`

```diff
 Tag = project
+ID = startProjectBuild
-POST /project/{projectid}/{stage}/run
+POST /project/{projectId}/build
```

- The `{stage}` path parameter has been moved to a query parameter. Now uses
  `?stage=ALL` by default.

### `GET /provider`

```diff
 Tag = provider
+ID = getProviderList
-GET /providers
+GET /provider
```

```diff
 NAME               PARAM    TYPE            REQUIRED?  DESCRIPTION
+limit              (query)  integer         false      Max number of items returned.
+offset             (query)  integer         false      Shifts the window returned.
+orderby            (query)  array[string]   false      Alphabetically, or order by ID?
+name               (query)  string          false      Filter on name hard match
+nameMatch          (query)  string          false      Filter on name soft match
+uploadUrl          (query)  string          false      Filter on uploadUrl hard match
+uploadUrlMatch     (query)  string          false      Filter on uploadUrl soft match
+url                (query)  string          false      Filter on url hard match
+urlMatch           (query)  string          false      Filter on url soft match
+tokenId            (query)  integer         false      Filter on token by ID
```

### `POST /provider`

```diff
 Tag = provider
+ID = createProvider
 POST /provider
```

### `GET /provider/{providerId}`

```diff
 Tag = provider
+ID = getProvider
-GET /provider/{providerid}
+GET /provider/{providerId}
```

### `PUT /provider/{providerId}`

```diff
 Tag = provider
+ID = updateProvider
-PUT /provider
+PUT /provider/{providerId}
```

- Added path parameter `{providerId}` for value that was taken from the HTTP
  request body.

### `POST /provider/search`

```diff
 Tag = provider
-POST /providers/search
```

- Deprecated. Please refer to the `GET /provider` instead.

### `GET /token`

```diff
 Tag = token
+ID = getTokenList
-GET /tokens
+GET /token
```

```diff
 NAME           PARAM    TYPE            REQUIRED?  DESCRIPTION
+limit          (query)  integer         false      Max number of items returned.
+offset         (query)  integer         false      Shifts the window returned.
+orderby        (query)  array[string]   false      Alphabetically, or order by ID?
+userName       (query)  string          false      Filter on userName hard match
+userNameMatch  (query)  string          false      Filter on userName soft match
+token          (query)  string          false      Filter on token hard match
```

### `POST /token`

```diff
 Tag = token
+ID = createToken
 POST /token
```

### `POST /token/search`

```diff
 Tag = token
-POST /tokens/search
```

- Deprecated. Please refer to the `GET /token` instead.

### `GET /token/{tokenId}`

```diff
 Tag = token
+ID = getToken
-GET /token/{tokenId}
+GET /token/{tokenId}
```

### `PUT /token/{tokenId}`

```diff
 Tag = token
+ID = updateToken
-PUT /token
+PUT /token/{tokenId}
```

- Added path parameter `{tokenId}` for value that was taken from the HTTP
  request body.

## Compatibility

This will break a lot of systems. Some rely on the "add or update" mechanics
that I'm proposing to remove. But those systems should still be operable until
v6, and IIRC that's the provider APIs that rely on them to simplify their
own code.

I have great plans for v6 with the [Hide providers behind API](https://iver-wharf.github.io/wharf-notes/hide-providers-behind-api)
approach. This will render most of the "provider to API" communication obsolete
as the API will rely on the provider's responses instead of requests.

Again, it's of utmost importance that the old endpoints works as before,
otherwise this will break Wharf for a long while.

## Alternative solutions

<!--
You pronounce one solution in this RFC, but keep the other alternatives you can
think about in here.
-->

- Going with plural instead of singular endpoints. Though I have a personal
  preference for the singular word forms. This is favorable if we later
  encounter some of those words that change drastically, such as
  "person" vs "people".

- Still allowing `POST /api/.../search` to allow complex queries.

  While this can be useful, it's not required for today's use cases. Not
  banning POST searches for future use, but for these simpler search queries
  they do not fit well.

  Up until (and including) v4, the POST search endpoints accepted the database
  models as the HTTP request body and then did a GORM `.Where` clause
  on the unsanitized input. This is difficult to expand with custom search
  queries. If we reintroduce POST search queries, that would then be to allow
  complex queries such as "if name contains 'foo' and ID > 5; or description
  is longer than 300 chars".

## Future possibilities

<!--
Does this lay groundwork for some future changes? If so, what?
-->

- As mentioned in the [#Compatibility](#compatibility), I have great plans for
  v6 with the [Hide providers behind API](https://iver-wharf.github.io/wharf-notes/hide-providers-behind-api)
  redesign. These changes in this RFC places the API on a steady concrete
  ground, instead of building on top of more dirt and slag.

- For the search endpoints, it will be easier to add more query parameters to
  allow finer search, compared to the previous solution.

## Unresolved questions

- Does update-specific request models need their own models? Or may we reuse
  the creation-specific request models for both cases?

  Ex reuse `request.Provider` instead of having `request.ProviderUpdate`.

- Is `-Match` a good suffix for the "soft match" fields? Could perhaps borrow
  the SQL term "Like" (as [Camunda is doing](https://docs.camunda.org/manual/latest/reference/rest/task/get-query/))
  but that feels like mixing the wrong domains.

  Any suggestions?
