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

Initialize a new document interactively from the template.

```bash
avk-docs init <document-name>
```

Run this command from the directory where you want the document folder to be created.  
The script will ask:

- **Document type** — `book` (formal, chapter-numbered) or `article` (simple letter/notes)
- **Title page** — whether to include a cover page
- **Metadata** — product name, document title, number, type, authors, version, date
- **Sections** — inner cover, revision history, table of contents, figure list, table list

Sections that are not needed are commented out in `book.adoc`. Unused files (e.g. `revision_history.adoc`) are deleted automatically.

```bash
cd ~/Documents/my-project
avk-docs init my-document
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

## Document Structure (`document-example`)

`document-example/` is a reference document used as the template source for `avk-docs init`.

```
document-example/
├── book.adoc                  # Main entry point — includes all sections
├── metadata.adoc              # Document metadata (title, authors, version, etc.)
├── _document_settings.adoc    # AsciiDoc/PDF rendering settings
├── revision_history.adoc      # Revision history table
├── pages/                     # (empty — user-created content pages go here)
├── images/                    # Source images referenced in the document
├── generated-images/          # Auto-generated diagram images (asciidoctor-diagram)
└── output/                    # Build output (PDF, HTML)
```

### `book.adoc`

The main entry point that assembles the full document.

```asciidoc
include::metadata.adoc[]
include::_document_settings.adoc[]

:doctype: book          ← document type: book or article

= {document-title}: {product-name}

// Document information (속표지)
include::../template/pages/document_information.adoc[]

// Revision history
include::revision_history.adoc[]

// Table of contents
toc::[]

// Figure list
include::../template/pages/figure_list.adoc[]

// Table list
include::../template/pages/table_list.adoc[]

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
| `:product-name:` | Product name — appears as the document subtitle |
| `:document-title:` | Document title — appears as the main title |
| `:document-number:` | Document number (e.g. `AVK-NAV-0001`) |
| `:module-name:` | Module name, or `-` if not applicable |
| `:document-type:` | Type of document (e.g. `Design Document`, `Test Report`) |
| `:project-manager:` | Project manager name |
| `:final-editor:` | Primary author / final editor |
| `:authors:` | Additional authors (comma-separated) |
| `:document-version:` | Version string (e.g. `1.0.0`). Comment out both this and `:revnumber:` if unused |
| `:release-date:` | Release date (`YYYY-MM-DD`). Comment out both this and `:revdate:` if unused |

Attributes that are not applicable should be commented out (`//`), except `:authors:` which should be left as an empty value.

