#!/usr/bin/env bash
# Synthetic fixture entrypoint — fails immediately with a clear diagnostic.
# TOOL: Read
echo "Error: required local dependency 'diff-lint' not found on PATH" >&2
exit 1
