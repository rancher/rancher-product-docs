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

mcm-local:
	mkdir -p tmp
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-local.yml \
		2>&1 | tee tmp/mcm-local-build.log 2>&1

mcm-remote:
	mkdir -p tmp
	npm ci
	npx antora --version
	npx antora --stacktrace --log-format=pretty --log-level=info \
		playbook-mcm-remote.yml \
		2>&1 | tee tmp/mcm-remote-build.log 2>&1

clean:
	rm -rf build

environment:
	npm ci

preview:
	npx http-server build/site -c-1
