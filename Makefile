local:
	mkdir -p tmp
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-local.yml \
		2>&1 | tee tmp/local-build.log 2>&1

remote:
	mkdir -p tmp
	npm ci
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-remote.yml \
		2>&1 | tee tmp/remote-build.log 2>&1

srfa-local:
	mkdir -p tmp
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-srfa-local.yml \
		2>&1 | tee tmp/srfa-local-build.log 2>&1

srfa-remote:
	mkdir -p tmp
	npm ci
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-srfa-remote.yml \
		2>&1 | tee tmp/srfa-remote-build.log 2>&1

clean:
	rm -rf build

environment:
	npm ci

preview:
	npx http-server build/site -c-1
