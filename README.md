# document-tools

AsciiDoc-based document template for Avikus technical documents.  
Builds PDF and HTML using a Docker-based Asciidoctor pipeline.

---

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (with Docker Compose v2)
- Python 3 (for `avk-docs serve html`)

---

## Installation

Clone the repository, then run the installer once:

```bash
git clone https://github.com/WonchulYoo/document-tools.git
cd document-tools
sudo ./install.sh
```

This copies the template assets to `/usr/local/share/document-tools/`, installs a symlink for `avk-docs` in `/usr/local/bin/`, and builds the Docker image.

**Custom prefix:**
```bash
sudo PREFIX=/opt/local ./install.sh
```

**Uninstall:**
```bash
sudo ./install.sh uninstall
```

---

## Commands

All commands are accessed through the `avk-docs` CLI.

```
avk-docs <command> [subcommand] [arguments]
```

Run `avk-docs --help` or `avk-docs <command> --help` at any time to see usage.

---

### `avk-docs init`

Initialize a new document interactively from one of the bundled templates.

```bash
avk-docs init <document-name>
```

Run this command from the directory where you want the document folder to be created.  
The script will ask:

- **Document template** — `document`, `letter`, or `test-report`
- **Metadata** — tags read from the selected template's `metadata.adoc`
- **Sections** — inner cover, revision history, table of contents, figure list, table list for the `document` template

Metadata questions are generated from comments near each attribute in `metadata.adoc`.
Sections that are not needed are commented out in `document.adoc`. Unused files (e.g. `revision_history.adoc`) are deleted automatically.

```bash
cd ~/Documents/my-project
avk-docs init my-document
avk-docs init --template letter my-letter
avk-docs init -y --template test-report my-test-report
```

---

### `avk-docs build pdf`

Build a PDF from an AsciiDoc document directory.

```bash
avk-docs build pdf <document-name> [version]
```

| Argument | Description |
|---|---|
| `document-name` | Name of the document directory (relative to current directory) |
| `version` _(optional)_ | Version string to append to the output filename |

**Output:** `<document-name>/output/<document-name>.pdf`  
**With version:** `<document-name>/output/<document-name>_<version>.pdf`

```bash
avk-docs build pdf my-document
avk-docs build pdf my-document 1.0.0
```

---

### `avk-docs build html`

Build an HTML site from an AsciiDoc document directory.

```bash
avk-docs build html <document-name>
```

**Output:** `<document-name>/output/html/index.html`

```bash
avk-docs build html my-document
```

---

### `avk-docs serve html`

Serve the built HTML locally in a browser at `http://localhost:8000`.

```bash
avk-docs serve html <document-name>
```

> Run `avk-docs build html` first if the HTML output does not exist yet.

```bash
avk-docs serve html my-document
```

---

## Init Templates

`avk-docs init` can create a new directory from one of these reference templates:

| Template | Description |
|---|---|
| `document` | Formal technical document |
| `letter` | Simple letter or note |
| `test-report` | Formal test report with summary and test pages |

## Document Structure (`document`)

`document/` is the formal document reference template.

```
document/
├── document.adoc              # Main entry point — includes all sections
├── metadata.adoc              # Document metadata (title, authors, version, etc.)
├── _document_settings.adoc    # AsciiDoc/PDF rendering settings
├── revision_history.adoc      # Revision history table
├── pages/                     # (empty — user-created content pages go here)
├── images/                    # Source images referenced in the document
├── generated-images/          # Auto-generated diagram images (asciidoctor-diagram)
└── output/                    # Build output (PDF, HTML)
```

### `document.adoc`

The main entry point that assembles the full document.

```asciidoc
include::metadata.adoc[]
include::_document_settings.adoc[]

:doctype: book

= {info-document-title}: {info-product-name}

// Document information (속표지)
doc-info-page::[]

// Revision history
include::revision_history.adoc[]

// Table of contents
toc::[]

// Figure list
figure-list::[]

// Table list
table-list::[]

== Chapter 1
```

**Title page behavior:**

| `doctype` | Default | To disable | To enable |
|---|---|---|---|
| `book` | Included | Add `:notitle:` | — |
| `article` | Not included | — | Add `:title-page:` |

---

### `metadata.adoc`

Document metadata attributes. These are referenced throughout the document and in the PDF theme.

| Attribute | Description |
|---|---|
| `:info-product-name:` | Product name — appears as the document subtitle |
| `:info-document-title:` | Document title — appears as the main title |
| `:info-document-number:` | Document number (e.g. `AVK-NAV-0001`) |
| `:info-module-name:` | Module name, or `-` if not applicable |
| `:info-document-type:` | Type of document (e.g. `Design Document`, `Test Report`) |
| `:info-project-manager:` | Project manager name |
| `:info-final-editor:` | Primary author / final editor |
| `:info-authors:` | Additional authors (comma-separated) |
| `:info-document-version:` | Version string (e.g. `1.0.0`). Comment out both this and `:revnumber:` if unused |
| `:info-issue-date:` | Release or issue date (`YYYY-MM-DD`). Comment out both this and `:revdate:` if unused |

Attributes that are not applicable should be commented out (`//`), except `:info-authors:` which should be left as an empty value.
