# Using Fontist in CI

Fontist works well in CI environments too! You can just `gem install fontist` like normal to get up and running. Hoever, if you don't like waiting for it to compile the native Ruby extensions each time you `gem install fontist` then you might be interested in our premade custom CI helpers.

```sh
# This works on your PC and in CI! 🚀
gem install fontist
```

ℹ Make sure your CI runner has an appropriate version of Ruby installed.

## GitHub Actions

If you want to use Fontist in GitHub Actions you can use the [fontist/setup](https://github.com/fontist/setup) action to automagically ✨ configure Fontist in the GitHub Actions environment. This lets you install fonts and use them in your CI process. Here's an example:

```yml
on: push
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: fontist/setup@v1
      - run: fontist install "Fira Code"
      - run: fontist install "Open Sans"
      # Now you can use the installed fonts!
```

[📚 Read more on the fontist/setup GitHub page](https://github.com/fontist/setup)
