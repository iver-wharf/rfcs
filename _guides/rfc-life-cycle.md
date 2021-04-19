---
layout: default
title: RFC life cycle
last_modified_date: 2021-04-19
---

# RFC life cycle

1. **RFC PR is created.** This step is done by anyone. Read the [Writing RFCs](./writing-rfcs.md)
   page about the template to use, how to push it so we can see it, things to
   keep in mind, and so on.

   But keep in mind, do not start something you're not willing to finish. If we
   have questions about your RFC, it will speed things up a lot if you
   [the author] is there to respond to our questions.

2. **RFC goes into review.** Again, anyone may participate here. But the
   developers/[collaborators](https://docs.github.com/en/github/getting-started-with-github/github-glossary#collaborator)
   of Wharf have the final saying in any descision and discussion, especially
   in *"endless discussions"*.

   Our goal is that a newly created RFC is reviewed around 1-2 weeks after
   creation.

3. **A descision is made.** Will the RFC be rejected, published, or postponed?
   Case by case basis here. Rejected and postponed RFC shall have an
   explanational comment by the developer/collaborator who closed/postponed the
   RFC to summarize the review discussions and explain the descision.

   - Published/approved: PR merged
   - Rejected: PR closed
   - Postponed: Label `postponed` is added to the PR

   The person who makes this descision is a collaborator of descending
   preferred order:

   1. Author of RFC, given they are a [collaborator](https://docs.github.com/en/github/getting-started-with-github/github-glossary#collaborator).
   2. Collaborator who has been heavily active in the discussion.
   3. Collaborator whose skill matches the subject of the RFC. Ex: frontend.
   4. Any other collaborator.

4. *[For postponed RFCs]* **RFC is picked back up.** This could be as simple as
   leaving a new comment on a RFC PR (marked with `postponed` label) where you
   bring up some new concern or possible solution, all while trying to tackle
   the reason it was postponed in the first place.

## Published RFCs

Once a RFC has been published, it is not touched again. With the exception of:

- semantically intact typo changes, or
- fixing outdated links.

## Rejected RFCs

A rejected RFC **does not** mean its proposal can never be suggested again.

If circumstances changes, or a new viewpoint or idea of new implementation
angle arises, then the idea from the rejected RFC is more than welcome back,
but as a new proposed RFC. The original rejected RFC is not touched, though
you are adviced to reference it in your new RFC.

## Postponed RFCs

There is no time limit on a postponed RFC. All it says is that we
(Wharf collaborators) will not proceed with said RFC right now, but still
leaving the door open for us to return to it later.
