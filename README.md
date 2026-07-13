# SUSE® Rancher Prime and Rancher Manager Documentation

This is the source for the official SUSE Rancher Prime, SUSE Rancher for AWS and Rancher Manager documentation.

For inquiries about the Rancher software, please refer to [Rancher GitHub repository](https://github.com/rancher/rancher/).

## Build the Documentation Site

This repository uses [Antora](https://docs.antora.org/antora/latest/) to build [AsciiDoc](https://docs.asciidoctor.org/asciidoc/latest/) content into a static website.

### Prerequisites

#### git

You need git to get the source code of this repository. Run the command below to check whether git is installed on your machine.

```
git --version
```

If you don't have git installed on your machine, it is recommended to install it through your operating system or distribution's package manager. Otherwise, you can download and install from the [git downloads](https://git-scm.com/downloads) page.

#### Node.js

Antora requires an active long term support (LTS) release of Node.js. Run the command below to check if you have Node.js installed, and which version. This command should return an [active Node.js LTS version number](https://nodejs.org/en/about/releases/).

```
node -v
```

If you don't have Node.js installed on your machine, install it, preferably via [nvm](https://github.com/nvm-sh/nvm).

### Install Dependencies

#### Git Submodules

This repository uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to manage some of its dependencies, including the Antora files that provide the custom GUI for the documentation website. Run the command below to initialize the submodules.

```
git submodule update --init
```

After initializing, and whenever the referenced commits for the submodules are updated in the repository (such as after a `git pull`), you need to use the `update` command to fetch the latest data for the submodules:

```
git submodule update
```

#### Node Modules

Open a terminal at the root of the git repository. Run the command below.

```
npm ci
```

### Build the Static Website Using the Local Documentation Content

There are several playbook files available to build different variants of the documentation site, such as the community (Rancher Manager), product (Rancher Prime), or SRFA (SUSE Rancher for AWS) site, using either local or remote content.

If you want to build and view the documentation content from your local machine, you can use one of the local playbooks:

- `playbook-community-local.yml`
- `playbook-product-local.yml`
- `playbook-srfa-local.yml`

Run the command below to build the site using your chosen playbook file, replacing `<PLAYBOOK_FILE>` with the respective playbook:

```
npx antora <PLAYBOOK_FILE>
```

To preview the built documentation using a local HTTP server, run the command below, replacing `<SITE_DIRECTORY>` with the corresponding build output directory (for example, `build/site-product-local`, `build/site-community-local`, or `build/site-srfa-local`):

```
npx http-server <SITE_DIRECTORY> -c-1
```

Alternatively, you can preview the documentation by accessing the HTML files directly. To do so, open the `<SITE_DIRECTORY>/index.html` file.

Subsequent updates require rebuilding (that is running `npx antora <PLAYBOOK_FILE>` again) as there is no live reloading.

### Using Make

Alternatively, you can use `make` to build and preview the documentation. Note that you must have the `make` package installed on your system to use this method.

The following targets are available in the `Makefile` for building the documentation locally:

- `make community-local`
- `make product-local`
- `make srfa-local`

To preview the built documentation using a local HTTP server, you can use the following targets:

- `make preview-community-local`
- `make preview-product-local`
- `make preview-srfa-local`

Other utility targets include `make environment` to install the `npm` dependencies, and `make clean` to remove the `build` directory.

## Contributing to the Documentation

You can contribute to the documentation by raising awareness about inaccuracies or suggesting changes directly. This can be done in two ways:

1. [Open an issue](https://github.com/rancher/rancher-product-docs/issues/new/choose).
1. Edit the documentation in the way you see fit and submitting a [pull request](https://github.com/rancher/rancher-product-docs/compare).

### Edit the Documentation

To get started, [fork](https://github.com/rancher/rancher-product-docs/fork) and clone the `rancher-product-docs` repository.

Our repository does not allow you to make changes directly to the `main` branch. Create a working branch and make pull requests from your fork to [rancher/rancher-product-docs](https://github.com/rancher/rancher-product-docs).

### Branching Strategy

Most documentation development happens on the `main` branch. However, when working on version-specific content, your pull requests should target a version branch (for example, `v2.10.10`). These version branches are created at the beginning of the development cycle for a specific release. Once the version is released, the release branch is merged back into `main`.

An exception to this is a new minor version (such as `v2.10.0`), for which development is opened on `main` from the beginning of the development cycle.

### File Organization

#### Content and Asset Files

There are two separate directory trees for documentation content:

- `community-docs/<VERSION>/`: Contains content for the community site, published at https://ranchermanager.docs.rancher.com/.
- `versions/<VERSION>/`: Contains content for the Prime site, published at https://documentation.suse.com/cloudnative/rancher-manager/.

To support single-sourcing, most of the AsciiDoc files in the `community-docs` tree are symlinked to their respective counterparts in the product `versions` directory. For community docs, these files are organized under the following directory structure:

- `community-docs/<VERSION>/modules/ROOT/pages/`

For product docs, the directory structure is as follows:

- `versions/<VERSION>/modules/<LOCALE>/pages/`

To define the location of the documentation page in the product `versions` documentation tree and its community symlink counterpart in the `community-docs` tree, use the `:community-path:` and `:product-path:` attributes at the top of the AsciiDoc file.

For example:

```asciidoc
:community-path: reference-guides/kubernetes-concepts.adoc 
:product-path: about-rancher/concepts.adoc
```

Other asset files (for example, images) have their own subdirectories. For example, `versions/<VERSION>/modules/en/images`.

#### Backporting Changes

When you need to backport changes between different versions, you can try running the `./product-docs-common/scripts/recurring/backport_modules.sh` script. This script helps contributors with porting changes as found in Git-modified files.

For example, to port changes to versions `v2.11` and `v2.12`, run:

```bash
./product-docs-common/scripts/recurring/backport_modules.sh v2.11 v2.12
```

For more information and a complete list of options, refer to the script's help menu by running:

```bash
./product-docs-common/scripts/recurring/backport_modules.sh --help
```

#### Single-Sourcing with Conditionals

Because most documentation content is single-sourced and shared across the community, product (Rancher Prime), and SRFA (SUSE Rancher for AWS) sites, you might encounter situations where certain text, links, or instructions apply to only one specific build type.

To handle these differences, use AsciiDoc `ifeval::[]` conditionals based on the `{build-type}` attribute. This ensures the appropriate content is selectively rendered for the respective target site.

Here are some practical examples of how to use these conditionals in the `.adoc` files:

```asciidoc
// Content specifically for the community site
ifeval::["{build-type}" == "community"]
This content only appears in the Rancher Community documentation.
endif::[]

// Content specifically for the Prime site
ifeval::["{build-type}" == "product"]
This content only appears in the SUSE Rancher Prime documentation.
endif::[]

// Content specifically for the SUSE Rancher for AWS (SRFA) site
ifeval::["{build-type}" == "srfa"]
This content only appears in the SUSE Rancher for AWS documentation.
endif::[]

// Content for everything except the SRFA site (that is, applies to both product and community build types)
ifeval::["{build-type}" != "srfa"]
This content applies to both the Rancher Community and SUSE Rancher Prime documentation, but is excluded from SRFA.
endif::[]
```

For more information on the directive syntax, refer to the [AsciiDoc Conditionals documentation](https://docs.asciidoctor.org/asciidoc/latest/directives/conditionals/).

#### Required Anchor IDs for Headings

To support content translations, you must use explicit anchors for cross-references. Auto-generated anchors do not survive the translation process, which causes links to break.

When creating a heading, always define an explicit anchor directly above it. Use the following anchor format:

```asciidoc
[#_my_anchor]
== My Anchor

My paragraph.
```

You can then safely refer to this heading using the explicit anchor:

```asciidoc
xref:#_my_anchor[My Anchor]
```

> [!NOTE]
> If you want to link from one documentation page to another, do not use absolute URLs. Antora uses a special xref: syntax to cross-reference pages. For example:
>
> ```asciidoc
> xref:installation/requirements.adoc[System Requirements]
> ```
> For more information, refer to the [Antora Xref documentation](https://docs.antora.org/antora/latest/page/xref/).

#### Updating Navigation

When adding a new documentation page, or renaming or removing an existing one, you must update the navigation file (`nav.adoc`) for the respective version (and locale). This ensures that the site's sidebar menu accurately reflects the available content.

If the page is single-sourced, the `nav.adoc` file needs to be updated in both the community and product directory trees, for example:

- `community-docs/<VERSION>/modules/ROOT/nav.adoc`
- `versions/<VERSION>/modules/en/nav.adoc`

For more information on how to structure the navigation lists, refer to the [Antora Navigation Files and Lists documentation](https://docs.antora.org/antora/latest/navigation/files-and-lists/).

#### Configuration Files

- Site-level configuration is done through a playbook file. For example, `playbook-community-local.yml`. Refer to the [Antora playbook documentation](https://docs.antora.org/antora/latest/playbook/) for more information.
- Component-level configuration is done through a file called `antora.yml`. For example, `versions/<VERSION>/antora.yml` or `community-docs/<VERSION>/antora.yml`. Refer to the [Antora  antora.yml documentation](https://docs.antora.org/antora/latest/component-version-descriptor/) for more information.

#### Translations

Translations are only published for the Prime site and are available under the `versions/<VERSION>/modules/` directory. Translations are imported in batches, so contributors should not update individual translations manually.

The list of available locales for each page is defined by the `:page-languages:` attribute at the beginning of each page. This attribute is used for the language switcher on the Prime site.

#### Troubleshooting Common Issues

**Error:** `Antora documentation component not found` or CSS formatting looks completely broken.
**Fix:** You likely forgot to initialize the submodules. Run `git submodule update --init` and rebuild.

**Error:**  `npm ERR! code EBADENGINE` or dependency conflicts.
**Fix:** Ensure you are using a modern Node.js LTS version (e.g., Node 18 or Node 20). If you used `npm install`, delete your `node_modules` directory and run `npm ci` instead.

**Issue:** Changes aren't updating in the browser.
**Fix:** Antora does not feature "live-reload". Every time you make a change to a file, you must stop your terminal process, rerun `npx antora <PLAYBOOK_FILE>`, and refresh your browser.

## License

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