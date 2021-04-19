---
layout: default
title: Writing RFCs
last_modified_date: 2021-04-19
---

# Writing RFCs

If you're uncertain, make sure to read the [What needs an RFC](./what-needs-an-rfc.md)
page first.

## Creating the pull request

1. Fork the repository <https://github.com/iver-wharf/rfcs>

   > *For collaborators, meaning those of you with write access to the
   > repository, you may skip this step and instead operate directly on the
   > main repository.*

2. In your fork, create a new branch. Suggest to name it something in the lines
   of `rfc/name-of-my-feature`.

3. Copy the file `0000-template.md` from the repository root into the
   `_published/` directory.

4. Rename the file to match the name of your suggested feature, leading to the
   filename `_published/0000-name-of-my-feature`. *(Keep the number 0000. That
   will be changed in a later step.)*

5. Fill out the template. Try to fill out all the appropriate sections.

   If do not have anything to add to a section, please write:

   > *"Nothing comes to mind."*

   instead of removing the section.

6. Commit and push, then create a pull request (PR) from your newly created
   branch over to the `master` branch on <https://github.com/iver-wharf/rfcs>.

   Make sure to keep the "Allow edits by maintainers" checkbox ticked. We might
   push changes directly to your branch to speed up the process.

7. The RFC ID will be the PR number. If your created PR is #123, then the RFC
   ID becomes 123.

   After you've published your PR, please rename your RFC file to include this
   PR ID as well as the PR link in the top of the Markdown file. Again, if your
   created PR is #123, then rename your file:

   - *before:* `_published/0000-name-of-my-feature.md`
   - *after:* `_published/0123-name-of-my-feature.md`

8. Great! You're fully set up! Now just sit back and relax while we will review
   your RFC.

   Please stay alert though, as we will probably have some questions and
   discussions where your perspective will be very valuable.

## Keep it simple

Try to be brief in your explanations and get to the point quickly.

## Make sure you got the rights

Embedding code snippets or images inside your RFC will require you to in an
obvious way state where they are from and what license they fall under.

Safest bet is just to only refer to the source instead of embedding it.

We cannot merge RFCs that contain content that collides with our licenses,
namely the MIT license.

