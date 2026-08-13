---
applyTo: "**/*.0.adoc,**/*.1.adoc"
---
@copilot

* First, clean up the `__VERSION__.adoc` files in this PR:
  * Remove the entire `Security Fixes for Vulnerabilities` section if found.
  * Remove any bug fix release notes listed under `Major Bug Fixes` sections.
  * Remove any feature enhancements release notes listed under `Features and Enhancements` sections.
  * Move the issues listed under `Behavior Changes` and `Known Issues` sections to later in the document, to sections `Previous Rancher Behavior Changes` and `Long-standing Known Issues`. Older issues are listed with their respective categories, for example issued originally under `Cluster Provisioning` are moved to the `Long-standing Known Issues - Cluster Provisioning` section.
    * For each moved issue, list it under the release it was introduced in, for example `Rancher v2.13.1:`, following the format of other old issues.
* Next, use the search queries in the PR body to search for the issues labeled as `release-note` or `release-note-prime`.
* For each found issue, scan the body, comments, referenced Pull Requests and GitHub issues and labels to understand the full context of the Rancher __VERSION__ release and the status of the issue.
  * Summarize the scanned contents as a release note, following the format found in the `__VERSION__.adoc` files.
  * If the issue is a backport/forwardport, the issue will reference another issue that it is backported/forwardported from. Check the referenced issue to see if it has a `release-note` or `release-note-prime` label. If it does, reuse the existing description.
  * If the issue has a comment containing a Release Notes summary of the issue, reuse that as the description.
  * Update reused descriptions for clarity and grammar as needed.
*  Update the `__VERSION__.adoc` files with the summarized release notes, placing them under the correct section in the document. Attempt to determine the correct section by scanning issue labels for relevant areas and teams. If no suitable section can be determined, place the issue under `Rancher General`.
* For each issue under the specific section, determine the release note type of each issue and place it under the correct subsection category of `Features and Enhancements`, `Behavior Changes`, `Major Bug Fixes`, or `Known Issues`.
* Post a comment summarizing found issues, formatted as separate tables for each search query. Each table should also contain the determined category and found references to related issues or PRs.
* Scan issues found in the `Long-standing Known Issues` section in the `__VERSION__.adoc` files, follow the referenced links and list issues closed in the past 45 days in a table in the comment, including the date and a summary of the latest updates made to the issue. Ignore any closed as not planned issues.
  * If the scanned long-standing known issues contain a comment with either a `/backport __VERSION__` or `/forwardport __VERSION__` in it, report this in the summary.
  * Then search for any `[backport]` or `[forwardport]` link references to determine the status of the long-standing known issue and update the summary and the document accordingly.
* Finally, remove empty placeholder sections in the document.
