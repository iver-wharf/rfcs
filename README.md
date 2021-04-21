# Wharf RFCs (Request For Comments)

For any substantial change that needs to be thought through in Wharf, we try to
use RFCs for them instead of internally trying to talk it out in meetings.

Not every decision needs an RFC, nor is any RFC excessive. This is the
start of our journey with RFCs, so we're trying to limit them to changes with
major impact.

Read more about the Wharf RFC process over at the GitHub pages:
<https://iver-wharf.github.io/rfcs/>

## Disclaimer

The documents and markdown files in this repository are documentation of our
decision making. Only to have a place to look back at, similar to meeting
notes or recordings, so we can see our previous decisions.

**It is not** documentation of how things are meant to be implemented. Do not
take this repository as the source of truth of how Wharf works. Please check
out our [Wharf documentation](https://iver-wharf.github.io/) or the
[source code](https://github.com/iver-wharf/) itself to gain the actual source
of truth.

## Running locally

This repository is hosted using GitHub Pages, but you can also host it locally
if you want.

1. Install Jekyll requirements, such as Ruby v2.4.0 (or higher), GCC, and Make

   Jekyll's installation guide: <https://jekyllrb.com/docs/installation/#requirements>

2. Install `bundler` Ruby gem.

   You will need administrator access, so make sure to add `sudo` or run the
   terminal as administrator to be able to install these gems.

   ```sh
   # Linux/Mac
   $ sudo gem install bundler
   ```

   ```pwsh
   # Windows (PowerShell), make sure to start the terminal as administrator
   PS> gem install bundler
   ```

3. Install dependencies (Jekyll, Just-The-Docs theme, etc)

   ```sh
   bundle install

   # Optionally, if you have GNU make
   make install
   ```

4. Start the site. This does not need administrator access.

   ```sh
   bundle exec jekyll serve

   # Optionally add the --livereload flag for automatic refresh
   bundle exec jekyll serve --livereload

   # Optionally, if you have GNU make
   make serve
   ```

5. Visit the locally hosted page over at: <http://localhost:4000/>

---

Maintained by [Iver](https://www.iver.com/en).
Licensed under the [MIT license](./LICENSE).
