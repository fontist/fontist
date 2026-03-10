# Exit Codes

Fontist uses standard exit codes to indicate the result of command execution.

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Command completed successfully |
| 1 | UNKNOWN_ERROR | Unknown or unexpected error |
| 2 | NON_SUPPORTED_FONT_ERROR | Font is not supported by fontist |
| 3 | MISSING_FONT_ERROR | Font could not be found on the system or in formulas |
| 4 | LICENSING_ERROR | License agreement required but not accepted |
| 5 | MANIFEST_COULD_NOT_BE_FOUND_ERROR | Manifest file not found at specified path |
| 6 | MANIFEST_COULD_NOT_BE_READ_ERROR | Manifest file could not be read (invalid YAML or permissions) |
| 7 | FONT_INDEX_CORRUPTED | Font index file is corrupted and needs to be rebuilt |
| 8 | REPO_NOT_FOUND | Repository not found |
| 9 | MAIN_REPO_NOT_FOUND | Main formulas repository not found |
| 10 | REPO_COULD_NOT_BE_UPDATED | Repository could not be updated (network or git error) |
| 11 | MANUAL_FONT_ERROR | Manual font installation required (font cannot be downloaded) |
| 12 | SIZE_LIMIT_ERROR | Formula exceeds size limit. Use --size-limit, --newest, or --smallest options |
| 13 | FORMULA_NOT_FOUND | Formula not found for the requested font |
| 14 | FONTCONFIG_NOT_FOUND | Fontconfig is not installed or not found |
| 15 | FONTCONFIG_FILE_NOT_FOUND | Fontconfig configuration file not found |
| 16 | INVALID_CONFIG_ATTRIBUTE | Invalid configuration attribute specified |

## Using Exit Codes in Scripts

Exit codes are useful for scripting and CI/CD:

```sh
#!/bin/bash
fontist install "Roboto"
if [ $? -eq 4 ]; then
  echo "License acceptance required"
  fontist install "Roboto" --accept-all-licenses
fi
```

## Common Patterns

### CI/CD Pipelines

```yaml
# GitHub Actions example
- name: Install fonts
  run: |
    fontist install --accept-all-licenses --hide-licenses
    # Check for missing fonts
    if [ $? -eq 3 ]; then
      echo "Some fonts not found"
      exit 1
    fi
```

### Error Handling

```ruby
# Ruby script example
result = system("fontist install 'Roboto'")
case $?.exitstatus
when 0
  puts "Success"
when 3
  puts "Font not found"
when 4
  puts "License needs acceptance"
else
  puts "Unknown error"
end
```

## Related

- [CLI Reference](/cli/) - All CLI commands
