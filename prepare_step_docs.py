#!/usr/bin/env python3
"""Prepare local Docusaurus pages from custom-step READMEs.

No network requests, Git operations, publishing, or source-file edits.

Default outputs:
    website/docs/List of Steps/<README heading>.md
    website/static/img/<step folder>/<original image path>

Supported image forms:
    ![alt](img/example.png)
    ![alt](<img/example with spaces.png>)
    ![alt][image-reference]
    ![image-reference]
    <img src="img/example.png">

Markdown fenced code blocks are left unchanged.
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit


REPOSITORY_URL = (
    "https://github.com/sassoftware/sas-studio-custom-steps/tree/main"
)

EXCLUDED_FOLDERS = {
    ".git",
    ".github",
    ".venv",
    "venv",
    "node_modules",
    "website",
    "websites",
    "docs",
    "_template"
}

HEADING = re.compile(r"^ {0,3}#{1,2}[ \t]+(.+?)[ \t]*#*[ \t]*$")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
ALERT = re.compile(
    r"^ {0,3}>[ \t]*"
    r"\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\][ \t]*$",
    re.IGNORECASE,
)
QUOTE_LINE = re.compile(r"^ {0,3}>[ \t]?(.*)$")

# Support angle-bracket destinations and ordinary destinations containing
# balanced parentheses one level deep, with optional Markdown image titles.
DESTINATION = r"(?:<[^>\n]+>|(?:[^()\s\\]|\\.| \([^()\n]*\))+)"
# Spaces are permitted only inside the parenthesized subexpression above.
DESTINATION = DESTINATION.replace("| \\(", "|\\(")

INLINE_IMAGE = re.compile(
    rf"!\[(?:\\.|[^\]\\])*\]\("
    rf"[ \t]*(?P<url>{DESTINATION})"
    rf"""(?P<title>[ \t]+(?:"[^"\n]*"|'[^'\n]*'|\([^)\n]*\)))?"""
    rf"[ \t]*\)"
)
REFERENCE_IMAGE = re.compile(
    r"!\[(?P<alt>(?:\\.|[^\]\\])*)\]"
    r"(?:\[(?P<label>[^\]\n]*)\])?"
)
REFERENCE_DEFINITION = re.compile(
    rf"^(?P<prefix> {{0,3}}\[(?P<label>[^\]\n]+)\]:[ \t]*)"
    rf"(?P<url>{DESTINATION})(?P<tail>[^\n]*)$",
    re.MULTILINE,
)
HTML_IMAGE = re.compile(r"<img\b[^>]*>", re.IGNORECASE)
HTML_SRC = re.compile(
    r"""\bsrc\s*=\s*(?P<quote>["'])(?P<url>.*?)(?P=quote)""",
    re.IGNORECASE,
)

ALERT_TYPES = {
    "NOTE": "note",
    "TIP": "tip",
    "IMPORTANT": "info",
    "WARNING": "warning",
    "CAUTION": "danger",
}


@dataclass
class PlannedFile:
    data: bytes
    origin: str


def reference_key(label: str) -> str:
    return " ".join(label.split()).casefold()


def safe_filename(title: str) -> str:
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "-", title).strip(" .")
    if not name or name in {".", ".."}:
        raise ValueError(f"Cannot derive a filename from heading: {title!r}")

    # Windows reserved device names are unsafe even with an extension.
    stem = name.split(".", 1)[0].upper()
    reserved = {"CON", "PRN", "AUX", "NUL"}
    reserved |= {f"{prefix}{n}" for prefix in ("COM", "LPT") for n in range(1, 10)}
    if stem in reserved:
        name = "_" + name

    return name + ".md"


def readme_in(folder: Path) -> Path | None:
    matches = [
        p for p in folder.iterdir()
        if p.is_file() and p.name.casefold() in {"readme.md", "readme.markdown"}
    ]
    if len(matches) > 1:
        raise ValueError(f"Multiple Markdown READMEs in {folder}")
    return matches[0] if matches else None


def has_step_file(folder: Path) -> bool:
    return any(
        p.is_file() and p.suffix.casefold() in {".step", ".sas"}
        for p in folder.iterdir()
    )


def split_code_blocks(text: str) -> list[tuple[bool, str]]:
    """Return (is_fenced_code, text) chunks without editing their contents."""
    chunks: list[tuple[bool, str]] = []
    buffer: list[str] = []
    marker: str | None = None
    minimum_length = 0

    for line in text.splitlines(keepends=True):
        match = FENCE.match(line)

        if marker is None:
            if match:
                if buffer:
                    chunks.append((False, "".join(buffer)))
                    buffer = []
                marker = match.group(1)[0]
                minimum_length = len(match.group(1))
            buffer.append(line)
        else:
            buffer.append(line)
            closing = re.fullmatch(
                rf" {{0,3}}{re.escape(marker)}{{{minimum_length},}}[ \t]*",
                line.rstrip("\r\n"),
            )
            if closing:
                chunks.append((True, "".join(buffer)))
                buffer = []
                marker = None

    if buffer:
        chunks.append((marker is not None, "".join(buffer)))

    return chunks


def convert_alerts(text: str) -> str:
    lines = text.splitlines(keepends=True)
    output: list[str] = []
    index = 0

    while index < len(lines):
        match = ALERT.fullmatch(lines[index].rstrip("\r\n"))
        if not match:
            output.append(lines[index])
            index += 1
            continue

        kind = ALERT_TYPES[match.group(1).upper()]
        body: list[str] = []
        index += 1

        while index < len(lines):
            quoted = QUOTE_LINE.fullmatch(lines[index].rstrip("\r\n"))
            if not quoted:
                break
            body.append(quoted.group(1))
            index += 1

        body_text = "\n".join(body)

        # Use a longer delimiter if the body already contains ::: lines.
        colon_runs = [
            len(m.group(1))
            for m in re.finditer(r"(?m)^(:{3,})", body_text)
        ]
        delimiter = ":" * max(3, max(colon_runs, default=2) + 1)

        output.append(
            f"\n{delimiter}{kind}\n\n"
            f"{body_text}\n\n"
            f"{delimiter}\n\n"
        )

    return "".join(output)


class Converter:
    def __init__(self, root: Path, overwrite: bool) -> None:
        self.root = root
        self.docs = root / "website" / "docs" / "List of Steps"
        self.static = root / "website" / "static"
        self.overwrite = overwrite
        self.plan: dict[Path, PlannedFile] = {}
        self.doc_names: dict[str, Path] = {}
        self.pages = 0
        self.images: set[Path] = set()

    def add_file(self, destination: Path, data: bytes, origin: str) -> None:
        destination = destination.resolve()

        if not destination.is_relative_to(self.root):
            raise ValueError(f"Output escapes repository: {destination}")

        existing = self.plan.get(destination)
        if existing and existing.data != data:
            raise ValueError(
                f"Conflicting outputs for {destination}:\n"
                f"  {existing.origin}\n  {origin}"
            )

        self.plan[destination] = PlannedFile(data, origin)

    def rewrite_image(self, raw_url: str, readme: Path) -> str:
        wrapped = raw_url.startswith("<") and raw_url.endswith(">")
        value = raw_url[1:-1] if wrapped else raw_url

        # Markdown backslash escapes are not filesystem path separators.
        value = re.sub(r"\\([ !\"#$%&'()*+,\-./:;<=>?@\[\]^_`{|}~])", r"\1", value)
        parsed = urlsplit(value)

        # Remote, data, anchor-only, and existing root-relative URLs remain.
        if (
            parsed.scheme
            or parsed.netloc
            or value.startswith(("/", "#"))
            or not parsed.path
        ):
            return raw_url

        source = (readme.parent / unquote(parsed.path)).resolve()
        if not source.is_relative_to(self.root):
            raise ValueError(f"{readme}: image escapes repository: {raw_url}")
        if not source.is_file():
            raise ValueError(f"{readme}: image not found: {raw_url}")

        # Preserve folder structure for ordinary images. For ../ references,
        # use a stable, collision-resistant name rather than retaining "..".
        if source.is_relative_to(readme.parent):
            relative = source.relative_to(readme.parent)
        else:
            digest = hashlib.sha256(
                source.relative_to(self.root).as_posix().encode("utf-8")
            ).hexdigest()[:12]
            relative = Path("_shared") / f"{digest}-{source.name}"

        asset = Path("img") / readme.parent.name / relative
        destination = self.static / asset
        self.add_file(destination, source.read_bytes(), str(source))
        self.images.add(destination)

        url = "/" + quote(asset.as_posix(), safe="/-._~")
        if parsed.query:
            url += "?" + parsed.query
        if parsed.fragment:
            url += "#" + parsed.fragment

        return f"<{url}>" if wrapped else url

    def convert_images(
        self, text: str, readme: Path, image_labels: set[str]
    ) -> str:
        def inline(match: re.Match[str]) -> str:
            start, end = match.span("url")
            whole_start = match.start()
            original = match.group(0)
            return (
                original[: start - whole_start]
                + self.rewrite_image(match.group("url"), readme)
                + original[end - whole_start :]
            )

        text = INLINE_IMAGE.sub(inline, text)

        def definition(match: re.Match[str]) -> str:
            if reference_key(match.group("label")) not in image_labels:
                return match.group(0)
            return (
                match.group("prefix")
                + self.rewrite_image(match.group("url"), readme)
                + match.group("tail")
            )

        text = REFERENCE_DEFINITION.sub(definition, text)

        def html_tag(match: re.Match[str]) -> str:
            def source_attribute(attribute: re.Match[str]) -> str:
                old = attribute.group(0)
                start, end = attribute.span("url")
                offset = attribute.start()
                return (
                    old[: start - offset]
                    + self.rewrite_image(attribute.group("url"), readme)
                    + old[end - offset :]
                )

            return HTML_SRC.sub(source_attribute, match.group(0))

        return HTML_IMAGE.sub(html_tag, text)

    def convert_readme(self, readme: Path) -> None:
        text = readme.read_text(encoding="utf-8-sig")
        text = text.replace("\r\n", "\n").replace("\r", "\n")
        lines = text.splitlines(keepends=True)

        # Permit leading blank lines, but require the first content line
        # to be the title rather than guessing from a later heading.
        heading_index = next(
            (i for i, line in enumerate(lines) if line.strip()), None
        )
        if heading_index is None:
            raise ValueError(f"Empty README: {readme}")

        match = HEADING.fullmatch(lines[heading_index].rstrip("\n"))
        if not match:
            raise ValueError(
                f"{readme}: first nonblank line must be a # or ## heading"
            )

        title = match.group(1).strip()
        filename = safe_filename(title)
        key = filename.casefold()

        if key in self.doc_names:
            raise ValueError(
                f"Duplicate documentation filename {filename!r}:\n"
                f"  {self.doc_names[key]}\n  {readme}"
            )
        self.doc_names[key] = readme

        chunks = split_code_blocks(text)
        image_labels: set[str] = set()

        # Collect reference-image labels across the entire README before
        # rewriting definitions, which may occur before or after images.
        for is_code, chunk in chunks:
            if not is_code:
                without_inline = INLINE_IMAGE.sub("", chunk)
                for image in REFERENCE_IMAGE.finditer(without_inline):
                    label = image.group("label") or image.group("alt")
                    image_labels.add(reference_key(label))

        converted = "".join(
            chunk if is_code else convert_alerts(
                self.convert_images(chunk, readme, image_labels)
            )
            for is_code, chunk in chunks
        )

        converted_lines = converted.splitlines(keepends=True)
        folder_name = readme.parent.name
        folder_url = f"{REPOSITORY_URL}/{quote(folder_name, safe='')}"
        label = (
            folder_name.replace("\\", "\\\\")
            .replace("[", "\\[")
            .replace("]", "\\]")
        )

        admonition = (
            "\n\n:::note[**ACCESS THE CUSTOM STEP FOLDER**]\n\n"
            f"[{label}]({folder_url})\n\n"
            ":::\n\n"
        )

        # The opening heading is unchanged by the transformations above.
        converted_lines[heading_index] = (
            converted_lines[heading_index].rstrip("\n") + admonition
        )
        result = "".join(converted_lines).rstrip() + "\n"

        self.add_file(
            self.docs / filename,
            result.encode("utf-8"),
            str(readme),
        )
        self.pages += 1

    def execute(self, dry_run: bool) -> None:
        # Validate every output before writing any file.
        changes: list[tuple[Path, PlannedFile]] = []
        for destination, planned in sorted(self.plan.items()):
            if destination.exists():
                if not destination.is_file():
                    raise ValueError(f"Output is not a file: {destination}")
                if destination.read_bytes() == planned.data:
                    continue
                if not self.overwrite:
                    raise ValueError(
                        f"Existing file differs: {destination}\n"
                        "No files written. Use --overwrite to permit replacement."
                    )
            changes.append((destination, planned))

        for destination, planned in changes:
            relative = destination.relative_to(self.root)
            if dry_run:
                print(f"Would write: {relative}")
            else:
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(planned.data)
                print(f"Wrote: {relative}")

        verb = "planned" if dry_run else "processed"
        print(
            f"\n{self.pages} page(s), {len(self.images)} image(s) {verb}; "
            f"{len(changes)} file(s) "
            f"{'would change' if dry_run else 'changed'}."
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo",
        type=Path,
        default=Path.cwd(),
        help="Local repository root; defaults to the current directory.",
    )
    parser.add_argument(
        "--folder",
        action="append",
        default=[],
        help=(
            "Process only this top-level folder. Repeat for multiple folders. "
            "Explicit selection bypasses the .step/.sas detection rule."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Read and validate inputs; report outputs without writing files.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow replacement of existing output files whose contents differ.",
    )
    args = parser.parse_args()

    root = args.repo.resolve()
    if not root.is_dir():
        parser.error(f"Repository directory does not exist: {root}")

    try:
        if args.folder:
            folders = []
            for name in args.folder:
                folder = root / name
                if (
                    Path(name).name != name
                    or not folder.is_dir()
                    or folder.is_symlink()
                ):
                    raise ValueError(f"Not a regular top-level folder: {name}")
                folders.append(folder)
            folders = sorted(set(folders), key=lambda p: p.name.casefold())
        else:
            folders = sorted(
                (
                    folder
                    for folder in root.iterdir()
                    if folder.is_dir()
                    and not folder.is_symlink()
                    and not folder.name.startswith(".")
                    and folder.name.casefold() not in EXCLUDED_FOLDERS
                    and has_step_file(folder)
                ),
                key=lambda p: p.name.casefold(),
            )

        converter = Converter(root, args.overwrite)

        for folder in folders:
            readme = readme_in(folder)
            if readme is None:
                if args.folder:
                    raise ValueError(f"No Markdown README in {folder}")
                print(f"Skipped (no Markdown README): {folder.name}")
                continue
            converter.convert_readme(readme)

        if converter.pages == 0:
            raise ValueError("No custom-step READMEs matched.")

        converter.execute(args.dry_run)
        return 0

    except (OSError, UnicodeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())