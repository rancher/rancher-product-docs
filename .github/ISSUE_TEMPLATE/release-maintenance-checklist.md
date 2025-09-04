---
name: Release Maintenance Task Checklist
about: Track tasks that need to be done every release.
title: '<VERSION> - Rancher Manager Release Maintenance Task Checklist'
---

This issue is to track tasks that need to be done every release regardless of whether the release has new feature content or not.

> [!NOTE]  
> Links to published pages and source files are for reference only.
>
> Apply updates be to the version and language appropriate files as needed.

- [ ] Create a new branch for the release, such as `v2.12.1`. Release-specific updates should use this branch as its base.
- [ ] Update the release notes page tables:
  - [Published page](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/release-notes.html)
  - [Source](./blob/main/versions/latest/modules/en/pages/release-notes.adoc)
- [ ] Update the Rancher:webhook version mapping table:
  - [Published page](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/security/rancher-webhook/rancher-webhook.html)
  - [Source](./blob/main/versions/latest/modules/en/pages/security/rancher-webhook/rancher-webhook.adoc)
- [ ] Update the CNI popularity table partial:
  - [Published page](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/faq/container-network-interface-providers.html#_cni_community_popularity)
  - [Source](./blob/main/shared/modules/ROOT/partials/en/cni-popularity.adoc)
- [ ] Update the CSP adapter compatibility matrix:
  - [Published page](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/installation-and-upgrade/hosted-kubernetes/cloud-marketplace/aws/install-adapter.html#_rancher_vs_adapter_compatibility_matrix)
  - [Source](./blob/main/versions/latest/modules/en/pages/installation-and-upgrade/hosted-kubernetes/cloud-marketplace/aws/install-adapter.adoc)
- [ ] Update the deprecated features table:
  - [Published page](https://documentation.suse.com/cloudnative/rancher-manager/latest/en/faq/deprecated-features.html#_where_can_i_find_out_which_features_have_been_deprecated_in_rancher)
  - [Source](./blob/main/versions/latest/modules/en/pages/faq/deprecated-features.adoc)
- [ ] Update the `swagger-<VERSION>.json` file in `versions/<VERSION>/modules/en/attachments/`.
- [ ] Create a PR merging the release branch back into the `main` branch.
- [ ] Verify that the merged documentation is successfully built in the [`gh-pages`](https://github.com/rancher/product-docs-playbook/tree/gh-pages) branch of the [product-docs-playbook](https://github.com/rancher/product-docs-playbook) repo and then synced and published on [documentation.suse.com](https://documentation.suse.com/cloudnative/rancher-manager/)
