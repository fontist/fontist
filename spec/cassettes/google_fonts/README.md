# Google Fonts VCR Cassettes

This directory contains VCR cassettes for Google Fonts API tests. These cassettes cache HTTP responses to avoid hitting the real API during test runs.

## Security Notice

⚠️ **IMPORTANT**: The Google Fonts API key must NEVER be committed to the repository!

All cassettes use the placeholder `<GOOGLE_FONTS_API_KEY>` instead of real API keys. VCR is configured in [`spec/spec_helper.rb`](../../spec_helper.rb) to automatically filter sensitive data.

## Prerequisites

Before working with cassettes, you need a Google Fonts API key:

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the "Google Fonts Developer API"
3. Set the environment variable:
   ```bash
   export GOOGLE_FONTS_API_KEY=your_actual_api_key_here
   ```

## Cassette Types

### VCR Cassettes (Auto-generated)
These are created automatically when tests run with VCR recording enabled:

- `ttf_sample.yml` - Sample response from TTF endpoint
- `ttf_endpoint_trimmed.yml` - Trimmed TTF endpoint response
- `vf_endpoint_trimmed.yml` - Trimmed VF (Variable Fonts) endpoint response
- `woff2_endpoint_trimmed.yml` - Trimmed WOFF2 endpoint response
- `woff2_endpoint_mini.yml` - Minimal WOFF2 endpoint response

## Regenerating Cassettes

VCR automatically records responses from the Google Fonts API:

1. **Set up your API key**:
   ```bash
   export GOOGLE_FONTS_API_KEY=your_actual_api_key_here
   ```

2. **Delete existing cassettes** you want to regenerate:
   ```bash
   rm spec/cassettes/google_fonts/ttf_endpoint_trimmed.yml
   rm spec/cassettes/google_fonts/vf_endpoint_trimmed.yml
   rm spec/cassettes/google_fonts/woff2_endpoint_trimmed.yml
   ```

3. **Run tests with VCR recording**:

   VCR is configured to record new episodes by default in [`spec/support/vcr_setup.rb`](../../support/vcr_setup.rb).

   ```bash
   # Record all Google Fonts cassettes
   bundle exec rspec spec/fontist/import/google/data_sources/
   ```

   Or record specific endpoint:
   ```bash
   bundle exec rspec spec/fontist/import/google/data_sources/ttf_spec.rb
   bundle exec rspec spec/fontist/import/google/data_sources/vf_spec.rb
   bundle exec rspec spec/fontist/import/google/data_sources/woff2_spec.rb
   ```

4. **Verify API key was filtered**:
   ```bash
   grep -r "AIzaSy" spec/cassettes/google_fonts/
   # Should return NO results

   grep -r "<GOOGLE_FONTS_API_KEY>" spec/cassettes/google_fonts/
   # Should show the placeholder in all cassettes
   ```

5. **Commit the new cassettes**:
   ```bash
   git add spec/cassettes/google_fonts/
   git commit -m "chore: update Google Fonts VCR cassettes"
   ```

## Cassette Structure

Each VCR cassette contains:

```yaml
---
http_interactions:
- request:
    method: get
    uri: https://www.googleapis.com/webfonts/v1/webfonts?key=<GOOGLE_FONTS_API_KEY>
    body:
      encoding: US-ASCII
      string: ''
  response:
    status:
      code: 200
      message: OK
    body:
      encoding: UTF-8
      string: '{"kind":"webfonts#webfontList","items":[...]}'
recorded_at: Thu, 14 Dec 2024 00:00:00 GMT
```

## Testing Without API Key

Tests will automatically skip when `GOOGLE_FONTS_API_KEY` is not set:

```bash
# These tests will be skipped:
bundle exec rspec spec/fontist/import/google/data_sources/

# Output will show:
# Pending: (Failures listed here are expected and do not affect your suite's status)
#   1) ... GOOGLE_FONTS_API_KEY environment variable not set
```

## Troubleshooting

### "API key not set" error when recording
**Solution**: Set the environment variable:
```bash
export GOOGLE_FONTS_API_KEY=your_key
```

### API key appears in cassettes
**Solution**: This should NOT happen if VCR is configured correctly. Check:
1. VCR filter configuration in [`spec/spec_helper.rb`](../../spec_helper.rb)
2. Delete cassette and re-record

### Tests fail with existing cassettes
**Solution**: Cassettes may be outdated. Regenerate them:
```bash
rm spec/cassettes/google_fonts/*.yml
GOOGLE_FONTS_API_KEY=your_key bundle exec rspec spec/fontist/import/google/data_sources/
```

## VCR Configuration

VCR is configured in two places:

1. **Main configuration**: [`spec/spec_helper.rb`](../../spec_helper.rb)
   - Sets cassette library directory
   - Configures API key filtering
   - Sets default cassette options

2. **Support file**: [`spec/support/vcr_setup.rb`](../../support/vcr_setup.rb)
   - Additional VCR settings
   - Hook configuration

## Related Files

- [`spec/spec_helper.rb`](../../spec_helper.rb) - VCR configuration and API key filtering
- [`spec/support/vcr_setup.rb`](../../support/vcr_setup.rb) - Additional VCR setup
- [`spec/support/google_fonts_fixtures.rb`](../../support/google_fonts_fixtures.rb) - Fixture helpers

## Best Practices

1. ✅ **Always** verify API keys are filtered before committing
2. ✅ **Always** use environment variables for API keys
3. ✅ **Update** cassettes when API schema changes
4. ❌ **Never** commit actual API keys
5. ❌ **Never** commit cassettes with real keys in URIs