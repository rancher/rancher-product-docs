# Rancher Product Docs

Welcome to the Rancher Product docs.

This repo is used to migrate content from the [Rancher docs](https://ranchermanager.docs.rancher.com/) site to publish it on the [SUSE Documentation site](https://documentation.suse.com/). It runs on the [Antora](https://antora.org/) framework.

See the [Rancher software](https://github.com/rancher/rancher) repo if you have questions or requests for the Rancher platform.

## Contribute to Rancher Docs

If you are looking to update the currently published iteration of the Rancher docs site, please visit [https://github.com/rancher/rancher-docs](https://github.com/rancher/rancher-docs).

To start contributing, first install the Antora environment by running `make environment`.

Run `make local` to build the site into `build/site`. Open `build/site/index.html` to view.

Versioned documentation, including translations, is found under `versions/<version>/modules/<locale>/`.

## License

Copyright (c) 2014-2025 [SUSE, LLC.](https://www.suse.com/)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
