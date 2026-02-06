# SUSE® Rancher Manager Documentation

This repository is used to publish the documentation on the [SUSE Documentation website](https://documentation.suse.com/cloudnative/rancher-manager/). For inquiries about the Rancher software, please refer to [Rancher GitHub repository](https://github.com/rancher/rancher/).

## Build the Documentation Site

This repository uses [Antora](https://docs.antora.org/antora/latest/) to build [AsciiDoc](https://docs.asciidoctor.org/asciidoc/latest/) content into a static website.

### Prerequisites

#### git

You need git to get the source code of this repository. Run the command below to check whether git is installed on your machine.

```
git --version
```

If you don't have git installed on your machine, download and install it for your operating system from the [git downloads](https://git-scm.com/downloads) page.

#### Node.js

Antora requires an active long term support (LTS) release of Node.js. Run the command below to check if you have Node.js installed, and which version. This command should return an [active Node.js LTS version number](https://nodejs.org/en/about/releases/).

```
node -v
```

If you don't have Node.js installed on your machine, install it, preferably via [nvm](https://github.com/nvm-sh/nvm).

### Clone the Repository

Run the git command to clone this repository.

```
git clone https://github.com/rancher/rancher-product-docs.git
```

### Install Dependencies

#### Git Submodules

This repository uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to manage some of its dependencies, including the Antora files that provide the custom GUI for the documentation website. Run the command below to get the submodules.

```
git submodule update --init
```

#### Node Modules

Open a terminal at the root of the git repository. Run the command below.

```
npm ci
```

### Run Antora to Build the Static Website Using the Local Documentation Content

If you want to build and view the documentation content from your local machine you can do so with the `playbook-local.yml` file.

Run the command below to build using the `playbook-local.yml` file.

```
npx antora playbook-local.yml
```

To preview the built documentation using a local HTTP server, run the command below:

```
npx http-server build/site -c-1
```

Alternatively, you can preview the documentation by accessing the HTML files directly. To so so, open the `build/site/index.html` file.

Subsequent updates require rebuilding (i.e. running `npx antora playbook-local.yml` again) as there is no live reloading.

## Contributing to the Documentation

You can contribute to the documentation by raising awareness about inaccuracies or suggesting changes directly. This can be done in two ways:

1. [Open an issue](https://github.com/rancher/rancher-product-docs/issues/new/choose).
1. Edit the documentation in the way you see fit and submitting a [pull request](https://github.com/rancher/rancher-product-docs/compare).

### File Organization

#### Content and Asset Files

Most contributions will target these files and can be found under the `docs/<VERSION>/modules/<LOCALE>` directory.

- Content (AsciiDoc) files are found under the `pages` subdirectory. E.g. `docs/latest/modules/en/pages`.
- Other asset files (e.g. images) have their own subdirectories. E.g. `docs/latest/modules/en/images`.

#### Configuration Files

- Site-level configuration is done through a [playbook](https://docs.antora.org/antora/latest/playbook/) file. E.g. `playbook-local.yml`.
- Component-level configuration is done through a file called [`antora.yml`](https://docs.antora.org/antora/latest/component-version/). E.g. `docs/latest/antora.yml`.


## License
=======
Copyright (c) 2014-2026 [SUSE, LLC.](https://www.suse.com/)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.