---
layout: default
# This is just to fool remark-stringify not to escape & symbols
# See https://github.com/syntax-tree/mdast-util-to-markdown/issues/8
shields_io_query_params: label=issue%20state&logo=github&style=flat-square

# Update the following (it's YAML syntax)
pr_id: 29 # Update this with PR number/ID. No leading zeros
rfc_feature_name: wharf-api-migrations # Use kebab-case
title: "RFC-0029: wharf-api migrations" # Update this with PR number/ID and feature name. Use leading zeros
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

[GORM's auto migrations](https://gorm.io/docs/migration.html#Auto-Migration)
is great for simple migrations, but doesn't allow us to add custom migration
logic. This RFC proposes a way to add on to our migration flow to both not run
migrations when they're not needed as well as allow us to add any custom logic.

## Motivation

- Faster startup of wharf-api as it can skip GORMs auto migrations if not
  needed. Less important, but nice benefit.

- No excessive logging on startup caused by GORMs auto migration checks.

- Allows us to use apply custom code on migrations that GORM's auto migrations
  doesn't handle, as GORM's auto migrations only supports adding tables and
  columns but not changing or removing data.

## Explanation

### Storing migration state

Migration state model:

```go
// pkg/model/database/database.go

type Migration struct {
    MigrationID uint      `gorm:"primaryKey"`
    Comment     string    `gorm:"size:200"`
    AppliedAt   time.Time `gorm:"autoCreateTime"`
}
```

Sample data:

| migration_id | comment                             | applied_at           |
| ------------ | ----------------------------------- | -------------------- |
| 1            | Initial migration                   | 2021-01-31T12:49:00Z |
| 2            | Fix escaped strings in test results | 2021-02-02T14:12:00Z |

### Applying migrations

On startup, check the **highest** migration ID, and:

- if lower than latest migration: apply migrations.
- if equal: do nothing.
- if higher: error out, as this wharf-api binary doesn't support this DB layout.

To know what version is the latest, `migrations.go` in wharf-api will keep a
slice of migrations to apply, and then use the highest version there.

Each migration implementation is defined as a struct that implements the new
`migrater` interface:

```go
type migrater interface {
    meta() migrationMeta
    preMigrate(db *gorm.DB, latestAppliedID uint) error
    postMigrate(db *gorm.DB, latestAppliedID uint) error
}

type migrationMeta struct {
    id uint
    comment string
}
```

The code for applying these migrations look at a high level like this, where
the `migrations` slice is pre-calculated to only include the migrations not yet
applied:

```go
func applyMigrations(migrations []migrater, latestAppliedID uint) error {
    for _, mig := range migrations {
        err := mig.preMigrate(db, latestAppliedID)
        // handle err
    }
    
    err := applyAutoMigrations() // run db.AutoMigrate(tbl) on all models
    // handle err
    
    for _, mig := range migrations {
        err := mig.postMigrate(db, latestAppliedID)
        // handle err
    }
    
    return updateMigrationState(migrations) // adds migrations to `migrations` table
}
```

### Rollbacks

This implementation does not support performing rollbacks. If you have migrated
your database from migration ID 1 to migration ID 2, then there's no way to
revert this via wharf-api's migration implementation.

This is by design as it reduces the complexity for us tremendously.

What we mean with "rollbacks" is the feature of asking wharf-api to revert the
database to an older migration version by applying the rollback migrations in
reverse order from how they were applied. This is what's not supported.

In contrast, all migrations are applied in a transaction to allow
database-level rollbacks on migration errors to not leave the database in a
corrupt state.

## Compatibility

Nothing comes to mind.

## Alternative solutions

Skipping the `migrations` table and try to evaluate each migration if they need
to be applied. However this is more difficult in cases such as for
[wharf-api#133](https://github.com/iver-wharf/wharf-api/issues/133) that needs
to act on existing data, and performing this on every boot of wharf-api will be
a very heavy unnecessary performance loss.

## Future possibilities

With this in place we can do more complex migrations in the future, as we've
up until now been heavily restricted by only relying on GORM's `AutoMigrate`.

## Unresolved questions

Nothing comes to mind.
