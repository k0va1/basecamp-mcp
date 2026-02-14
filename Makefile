.PHONY: test lint-fix install

install:
	bundle install

test:
	bundle exec rake test

lint-fix:
	bundle exec standardrb --fix
