.PHONY: deps serve \
	lint lint-md \
	lint-fix lint-fix-md

deps:
	bundle install
	npm install

serve:
	bundle exec jekyll serve --livereload

lint: lint-md
lint-fix: lint-fix-md

lint-md:
	npx remark . .github

lint-fix-md:
	npx remark . .github -o
