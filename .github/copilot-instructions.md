# GitHub Copilot Instructions: SUSE Rancher Documentation

You are assisting contributors (writers, editors, engineers, and community members) working in the **SUSE Rancher Documentation** repository (`rancher-product-docs`). All contributors follow a single unified standard combining repository architecture from `README.md` and editorial style from `product-docs-common/ai-prompts/Style-Guide-onefile.md`.

---

## 1. Local Build & Verification Commands

- **Initialize Submodules & Dependencies**: `git submodule update --init --recursive && npm ci`
- **Build Product (Prime)**: `make product-local` (or `npx antora playbook-product-local.yml`)
- **Build Community**: `make community-local` (or `npx antora playbook-community-local.yml`)
- **Build SRFA**: `make srfa-local` (or `npx antora playbook-srfa-local.yml`)
- **Preview Sites**: `make preview-product-local` (port 8081) / `make preview-community-local` (port 8080) / `make preview-srfa-local` (port 8082)
- **Clean**: `make clean`

---

## 2. AsciiDoc & Single-Sourcing Invariants

- **Dual-Tree Layout**:
  - Product/Prime: `versions/<VERSION>/modules/<LOCALE>/pages/`
  - Community: `community-docs/<VERSION>/modules/ROOT/pages/`
  - AsciiDoc files in `community-docs` are symlinks to `versions/`.
- **Mandatory File Headers**:
  Every `.adoc` document must declare its path in both trees at the very top. It also needs to define a short description of the page, the revision date, and the list of other languages if other translations of the page exist:
  ```asciidoc
  :community-path: <path-relative-to-community-pages>
  :product-path: <path-relative-to-product-pages>
  :description: Explain Kubernetes concepts important for understanding Rancher, covering clusters, nodes, etcd, control plane, worker nodes, and Helm, with a simplified explanation
  :revdate: 2025-08-27
  :page-revdate: {revdate}
  :page-languages: [en, de, es, fr, ja, pt, zh]
  ```
- **Target Conditionals**:
  Use `ifeval::["{build-type}" == "..."]` directives (`community`, `product`, `srfa`, `!= "srfa"`).
- **Mandatory Explicit Heading Anchors**:
  Every section heading (`==`, `===`) must have an explicit anchor directly above it:
  ```asciidoc
  [#_heading_name]
  == Heading Name
  ```
  Auto-generated anchors break during translation.
- **Cross-References (`xref`)**:
  - Never use absolute domain URLs (e.g. `https://documentation.suse.com` or `https://ranchermanager.docs.rancher.com`).
  - Always use Antora `xref:path/to/page.adoc[Link Text]`.
  - Use attribute substitution when target paths differ between community and product builds.
- **Navigation (`nav.adoc`)**:
  When adding, moving, renaming, or deleting pages, update `nav.adoc` in both:
  - `community-docs/<VERSION>/modules/ROOT/nav.adoc`
  - `versions/<VERSION>/modules/en/nav.adoc`
- **Translations & Locales**:
  - Translations are published only for the Prime site under `versions/<VERSION>/modules/<LOCALE>/`.
  - Do not edit files in non-English translation directories unless explicitly instructed to do so; translations are imported in automated batches. Otherwise, only edit English source files (`modules/en/` and `community-docs/`).
  - Declare translated locales via `:page-languages:` in the document header for the Prime language switcher.
  - Always place explicit anchors (`[#_anchor_name]`) above headings so translation does not break cross-references.

---

## 3. SUSE Documentation Style Invariants

When drafting, revising, or reviewing text in pull requests or chat, enforce these rules:

- **Grammar & Voice**: American English, simple present tense, active voice, second person ("you").
- **Sentence Length**: Maximum 25 words per sentence. Split long or compound sentences.
- **Numbers**: Spell out numbers zero through nine; use numerals for 10 and above.
- **No Latin Abbreviations**: Replace `i.e.` with "that is", `e.g.` with "for example", avoid `etc.`, and avoid slash alternatives (`/`).
- **Tone & Word Choice**: Direct and professional. Avoid buzzwords (use "use", "help", "enable"; avoid "leverage", "utilize", "facilitate").
- **Terminology & Acronyms**: Expand acronyms on first use. Never use possessive forms of trademarks or acronyms ("the features of Rancher", not "Rancher's features").
- **Headings**: Sentence-style capitalization (capitalize first word and proper nouns only).
- **Inclusive Language**: Gender-neutral, culturally independent phrasing ("primary/secondary", "they/their").
- **Web & GEO Inverted Pyramid**: Provide a direct 40–80 word answer to primary user intent at the top of the section. Keep chunks to 1–3 paragraphs.
- **Modular Procedures**: Use numbered lists (`1. ... 2. ...`) with parallel grammatical phrasing.

---

## 4. Extended References

- Detailed build instructions, playbooks, and troubleshooting: `README.md`
- Complete SUSE Style Guide AI prompt: `product-docs-common/ai-prompts/Style-Guide-onefile.md`
