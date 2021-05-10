---
layout: default
title: What needs an RFC?
last_modified_date: 2021-04-19
---

# What needs an RFC

This list will be constantly evolving. For now, this is our current definition.

Take it with a grain of salt. None of these rules are absolute, and there are
lots of gray areas here.

## Definition

If your change you have in mind meets any of these critera, then you should
*probably* create an RFC for it:

1. Brings backward incompatible changes to the backend or the way you host
   Wharf.

2. Estimated large impact on users or developers of Wharf.

3. Estimated large effort to implement.

4. You want feedback on a proposal.

## Examples

- Wharf uses Jenkins, but we want to transition away from it. How do we run
  builds without Jenkins? **→ Definetly needs an RFC. Probably multiple**

- We want to change the syntax and schema of the `.wharf-ci.yml` file, while
  making it opt-in with a `version: v2` property inside the YAML file.
  **→ Actually a huge impact on the users. Definetly needs an RFC.**

- Bug fixes **→ Minor bugfix: No need for RFC. Major bugfix: Better safe
  than sorry, write an RFC for it.**
