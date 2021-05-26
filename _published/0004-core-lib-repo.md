---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 4 # Update this with PR number/ID. No leading zeros
rfc_feature_name: core-lib-repo # Use kebab-case
title: "RFC-0004: core-lib-repo" # Update this with PR number/ID and feature name. Use leading zeros
rfc_author_username: jilleJr
rfc_author_name: Kalle Jillheden # Or same as username, if you wish

# Leave these. Collaborator changes this before merging
impl_issue_id: 1
impl_issue_repo: iver-wharf/wharf-core
last_modified_date: 2021-05-19
---

# {{page.title}}

- RFC PR: [iver-wharf/rfcs#{{page.pr_id}}](https://github.com/iver-wharf/rfcs/pulls/{{page.pr_id}})
- Feature name: `{{page.rfc_feature_name}}`
- Author: {{page.rfc_author_name}} ([@{{page.rfc_author_username}}](https://github.com/{{page.rfc_author_username}}))
- Implementation issue: [{{page.impl_issue_repo}}#{{page.impl_issue_id}}](https://github.com/{{page.impl_issue_repo}}/issues/{{page.impl_issue_id}})
- Implementation status: ![GitHub issue state](https://img.shields.io/github/issues/detail/state/{{page.impl_issue_repo}}/{{page.impl_issue_id}}?{{page.shields_io_query_params}})

## Summary

Proposed location to place utility code, such as loading config values or
serving version endpoints, so that our other repositories can take use of it.

## Motivation

We start seeing some duplication of code in our repositories. Instead of
duplicating that code throughout the repos, we can collect them into a single
repository that the other repos then depend on.

This issue has been planned for a while, but put into motion by the
[review comment by @Pikabanga on iver-wharf/wharf-provider-github.](https://github.com/iver-wharf/wharf-provider-github/pull/5#discussion_r630345589)

## Explanation

The utility repository, <https://github.com/iver-wharf/wharf-core>, holds code
that does not solve any particular problems that's specific for the different
component's domains.

Instead, it is a place of common utility code. What you will find in this
utility repository is Go code that features:

- Reading configuration from files and/or environment variables
- Logging in a unified manner
- Serving common endpoints such as `GET /version`

What you will not find in this repository:

- ❌ Parsing `.wharf-ci.yml` files
- ❌ Abstractions over Kubernetes
- ❌ Abstractions over AMQP (already found in [iver-wharf/messagebus-go](https://github.com/iver-wharf/messagebus-go))
- ❌ Common database or HTTP JSON models

Sample:

```go
package main

import (
    "io/ioutil"
    _ "embed"

    "github.com/iver-wharf/wharf-core/pkg/app"
    "github.com/iver-wharf/wharf-core/pkg/config"
    "github.com/iver-wharf/wharf-core/pkg/ginutils"
    "github.com/iver-wharf/wharf-core/pkg/log"

    "github.com/gin-gonic/gin"
)

type DBConfig struct {
    Host     string `yaml:"host" env:"HOST"`
    Port     int    `yaml:"port" env:"PORT"`
    Username string `yaml:"username" env:"USERNAME"`
    Password string `yaml:"password" env:"PASSWORD"`
}

type Config struct {
    Logging log.Config      `yaml:"logging" env:"LOGGING"`
    API     ginutils.Config `yaml:"api" env:"API"`
    DB      DBConfig        `yaml:"db" env:"DB"`
}

type Version struct {
    app.Version
}

// go:embed version.yaml
var versionFile []byte

// @title Sample program
// @description This program takes use of the utility repository to load in
// @description the config and version of the app.
func main() {
    var version Version
    config.UnmarshalYAML(versionFile, &version, config.Options{})

    log.Infof("sample-program version=%s", version.AppVersion)

    var config Config
    configFile, _ := ioutil.ReadFile("config.yaml")
    config.UnmarshalYAML(configFile, &config, config.Options{
      AllowEnvironmentVariables: true,
    })

    log.SetConfig(config.Logging)

    log.Info("Successfully read config.")

    r := gin.Default()

    // func ApplyConfig(engine *gin.Engine, ginutils.Config)
    ginutils.ApplyConfig(r, config.API)

    // func AddVersionEndpoint(engine *gin.Engine, version interface{})
    ginutils.AddVersionEndpoint(r, version)

    r.Run()
}
```

```yaml
# config.yaml
logging:
  level: debug
  blacklist:
    - gin
    - gorm
api:
  allowCors: true

db:
  host: localhost
  port: 5432
  username: postgres
  password: changeit # Can be overritten with WHARF_DB_PASSWORD environment variable
```

```yaml
# version.yaml
$schema: https://github.com/iver-wharf/wharf-core/raw/master/pkg/app/version-schema.json
appVersion: v1.0.0
buildGitCommit: 5971d3b585a722536730c39a22aa3148993f2985
buildRef: 123
buildDate: 2021-05-12T13:55:00+02:00
```

## Compatibility

In architectural terms, this utility repository has to be "stable". Meaning it
will be a hassle to update as there will be so many components relying on it.

This may not be that big of an issue for added features though. It may induce
issues from time to time where we have to make 4 PRs each time we update the
logging library, but I \[Kalle] don't think that's a major issue as those
**components should not rely on the logic from the utilities repo to
cooperate.**

## Alternative solutions

Placing this inside the <https://github.com/iver-wharf/wharf-api> repository.
While this would work for most of the logic here, it does not play well later
when the `cmd` project wants to take use of these utilities as well, such as
the logging.

## Future possibilities

It allows for a unified way of configuring the services. If we can set a
unified convention of setting configs via files and being able to override them
with environment variables, then that would lift the operations-experience of
using Wharf to a much better level. Heavily inspired by the `appsettings.json`
solution for [configuring ASP.NET Core apps](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-5.0)

## Unresolved questions

1. What should be the name of the repo?

   | Suggestion                           | Votes                |
   | ----------                           | -----                |
   | github.com/iver-wharf/wharf-core     | @jilleJr, @Pikabanga |
   | github.com/iver-wharf/wharf-core-lib |                      |
   | github.com/iver-wharf/wharf-extra    |                      |
   | github.com/iver-wharf/wharf-utility  |                      |
   | github.com/iver-wharf/wharf-util     |                      |
   | github.com/iver-wharf/wharf-utils    | @iverestefans        |
