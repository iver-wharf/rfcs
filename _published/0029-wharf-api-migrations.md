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

### Third-party library

Library we are depending on is: <https://github.com/go-gormigrate/gormigrate>

```sh
go get -u github.com/go-gormigrate/gormigrate/v2
```

### Storing migration state

Migration state is kept by the table named `migrations`, and is a single
column table with the equivalent layout as the following GORM model:

```go
type Migration struct {
    ID string `gorm:"primaryKey"`
}
```

The table creation is defined in <https://github.com/go-gormigrate/gormigrate/blob/v2.0.0/gormigrate.go#L375-L382>.

Sample data:

| migration_id                |
| --------------------------- |
| 2016-08-30T14:00:00Z-v5.0.0 |
| 2016-08-30T14:15:00Z-v5.0.0 |
| 2016-08-30T14:30:00Z-v5.1.0 |

### Applying migrations

On start, wharf-api will invoke `gormigrate.Gormigrate.Migrate()`. Gormigrate
will handle the migration process, which looks something like this:

1. Checks for duplicate migrations.
2. Create migrations table (if not exists).
3. Check for unknown migrations found in the migrations table.
4. Apply schema initialization (if defined) if no migrations are found and exit.
5. Run all migrations not already applied.

### Rollbacks

While <https://github.com/go-gormigrate/gormigrate> supports migration
rollbacks, we will not make use of this feature. Instead, we will rely on
transactions for the migrations to have automatic rollbacks.

This means that a user will not be able to rollback their wharf-api version
from the hypothetical wharf-api v5.5.0 back to wharf-api v5.4.0. Such a feature
is left out to reduce complexity in wharf-api's code base. In other words: we
will not support downgrading wharf-api.

### Migration ID format

The following format will be used in the migration IDs:

```text
YYYY-MM-DDThh:mm:ssZ-VERSION
^^^^^^^^^^ ^^^^^^^^  ^^^^^^^
\    2   / \   3  /  \  1  /
```

Where:

1. `VERSION`: wharf-api version with `v` prefix.

2. `YYYY-MM-DD`: date in format of year-month-day, with month and day being
   left-padded with zeros.

3. `hh:mm:ss`: time in format of hour:minute:seconds, with hour ranging from
   00-23, and all being left-padded with zeros.

All above being values relative to when the migrations were written by the
developer. The date and time shall be is in UTC.

Example:

```text
2022-02-02T14:49:00Z-v5.0.0
```

### Writing migrations

We will follow Gormigrate's recommendation and redefine our models in each
migrations to declare the changes.

For example, if we have the following model in two different versions:

```go
// Hypothetical Build model in wharf-api v5.0.0
type Build struct {
	BuildID     uint
	Environment string
	Stage       string
}

// Hypothetical Build model in wharf-api v5.1.0
type Build struct {
	BuildID     uint
	Environment string
	Stage       string
	StartedBy   User
	StartedByID uint
}
```

Then the migrations would look like so:

```go
gormigrate.New(db, gormigrate.DefaultOptions, []*gormigrate.Migration{
	{
		ID: "2022-01-29T14:41:00Z-v5.0.0",
		Migrate: func(tx *gorm.DB) error {
			type Build struct {
				BuildID     uint
				Environment string
				Stage       string
			}
			return tx.AutoMigrate(&Build{})
		},
	},
	{
		ID: "2022-02-02T15:15:00Z-v5.1.0",
		Migrate: func(tx *gorm.DB) error {
			type Build struct {
				// only include new fields
				StartedBy   User
				StartedByID uint
			}
			return tx.AutoMigrate(&Build{})
		},
	},
})
```

### Initial migration

Gormigrate supports "initial migration", which is applied when no migrations
were found, and then skips all migrations and inserts all migrations into the
`migrations` table as if they have been applied. This speeds up migration time
and reduces unnecessary extra load on initial run with an empty database.

We will make use of this in wharf-api, and run our previous pre-Gormigrate
migration steps in this `InitSchema` function, where we only call GORM's
`AutoMigrate` on all tables and then we're done.

### Gormigrate options

We will be using the following configuration options:

```go
options := gormigrate.Options{
	TableName:                 "migrations",   // default
	IDColumnName:              "migration_id", // non-default
	IDColumnSize:              255,            // default
	UseTransaction:            true,           // non-default
	ValidateUnknownMigrations: true,           // non-default
}
```

The `// non-default` comments refer to the default options from <https://github.com/go-gormigrate/gormigrate/blob/v2.0.0/gormigrate.go#L77-L84>.

## Compatibility

Nothing comes to mind.

## Alternative solutions

- Skipping the `migrations` table and try to evaluate each migration if they
  need to be applied. However this is more difficult in cases such as for
  [wharf-api#133](https://github.com/iver-wharf/wharf-api/issues/133) that
  needs to act on existing data, and performing this on every boot of wharf-api
  will be a very heavy unnecessary performance loss.

- Use alternative library, such as:

  - <https://github.com/go-gorp/gorp>
  - <https://github.com/golang-migrate/migrate>
  - <https://github.com/pressly/goose>
  - <https://github.com/rubenv/sql-migrate>

  However they are all tailored to writing your own SQL, whereas the selected
  <https://github.com/go-gormigrate/gormigrate> library allows us to keep using
  GORM's fluent API of e.g `db.Model(&Build{}).Find(&builds)`.

- Write our own migration. This was suggested originally, and can be found in
  commit [c58124c](https://github.com/iver-wharf/rfcs/blob/c58124c9dfc0b931053b7c3d7ee03bcf5399d10c/_published/0029-wharf-api-migrations.md).

  As our needs for migration support is slim, we might revisit this and make our
  own anyway, but as it seems now this <https://github.com/go-gormigrate/gormigrate>
  library suits us just fine for now, and there's no need to overcomplicate
  things, even if it's fun to write our own libraries.

## Future possibilities

With this in place we can do more complex migrations in the future, as we've
up until now been heavily restricted by only relying on GORM's `AutoMigrate`.

## Unresolved questions

- Do we actually want to make use of rollbacks to support wharf-api downgrades?
