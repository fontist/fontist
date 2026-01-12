# Failing tests on GHA

Ubuntu failed because of this. This font file is no longer available, maybe we need to
change it to another font/formula (something from github will work):

```
Failures:

  1) Fontist::Font.install two formulas with the same font diff styles installs both
     Failure/Error: raise Errors::InvalidResourceError, errors.join(" ")

     Fontist::Errors::InvalidResourceError:
       Invalid URL: https://medarbejdere.au.dk/fileadmin/www.designmanual.au.dk/hent_filer/hent_skrifttyper/fonte.zip. Error: #<Down::ClientError: 418 I'm A Teapot>.
     # ./lib/fontist/resources/archive_resource.rb:32:in `download_file'
     # ./lib/fontist/resources/archive_resource.rb:20:in `archive'
     # ./lib/fontist/resources/archive_resource.rb:16:in `excavate'
     # ./lib/fontist/resources/archive_resource.rb:10:in `files'
     # ./lib/fontist/font_installer.rb:79:in `block in do_install_font'
     # ./lib/fontist/font_installer.rb:78:in `do_install_font'
     # ./lib/fontist/font_installer.rb:71:in `install_font'
     # ./lib/fontist/font_installer.rb:24:in `install'
     # ./lib/fontist/font.rb:253:in `request_formula_installation'
     # ./lib/fontist/font.rb:238:in `block in download_font'
     # ./lib/fontist/font.rb:237:in `each'
     # ./lib/fontist/font.rb:237:in `flat_map'
     # ./lib/fontist/font.rb:237:in `download_font'
     # ./lib/fontist/font.rb:73:in `install'
     # ./lib/fontist/font.rb:36:in `install'
     # ./spec/fontist/font_spec.rb:182:in `block (3 levels) in <top (required)>'
     # ./spec/fontist/font_spec.rb:658:in `block (5 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

NONE OF THE WINDOWS TESTS HAVE BEEN FUCKING FIXED!!!
```
Failures:

  1) Fontist::CLI#install with formula option formula from root dir returns success status and prints fonts paths
     Failure/Error: expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))

       (Fontist::Utils::UI (class)).say(include "AndaleMo.TTF")
           expected: 1 time with arguments: (include "AndaleMo.TTF")
           received: 0 times
     # ./spec/fontist/cli_spec.rb:303:in `block (5 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  2) Fontist::CLI#install with formula option formula from subdir returns success status and prints fonts paths
     Failure/Error: expect(Fontist.ui).to receive(:say).with(include("AndaleMo.TTF"))

       (Fontist::Utils::UI (class)).say(include "AndaleMo.TTF")
           expected: 1 time with arguments: (include "AndaleMo.TTF")
           received: 0 times
     # ./spec/fontist/cli_spec.rb:320:in `block (5 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  3) Fontist::CLI#install with formula option with misspelled formula name suggested formula is chosen installs the formula
     Failure/Error:
       expect(Fontist.ui).to receive(:say)
         .with(/texgyrechorus-mediumitalic\.otf/i)

       (Fontist::Utils::UI (class)).say(/texgyrechorus-mediumitalic\.otf/i)
           expected: 1 time with arguments: (/texgyrechorus-mediumitalic\.otf/i)
           received: 0 times
     # ./spec/fontist/cli_spec.rb:345:in `block (6 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  4) Fontist::CLI#manifest_locations contains one font with regular style returns font location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(output)

       (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108-8752-5llk1v/fonts/andale/AndaleMo.TTF"]}}})
           expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108-8752-5llk1v/fonts/andale/AndaleMo.TTF"]}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:692:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  5) Fontist::CLI#manifest_locations contains one font with bold style returns font location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(output)

      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:85:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:84:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  66) Fontist::Update private repo is set up before the main one fetches the main repo
      Failure/Error: git.fetch

      Git::FailedError:
        [{"GIT_DIR"=>"D:/a/_temp/d20260108-8752-3yzzay/versions/v4/formulas/.git", "GIT_WORK_TREE"=>"D:/a/_temp/d20260108-8752-3yzzay/versions/v4/formulas", "GIT_INDEX_FILE"=>"D:/a/_temp/d20260108-8752-3yzzay/versions/v4/formulas/.git/index", "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "--git-dir=D:/a/_temp/d20260108-8752-3yzzay/versions/v4/formulas/.git", "--work-tree=D:/a/_temp/d20260108-8752-3yzzay/versions/v4/formulas", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "fetch", "--", "origin"], status: pid 4040 exit 128, stderr: "fatal: unable to access 'https://github.com/fontist/formulas.git/': getaddrinfo() thread failed to start"
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1344:in `fetch'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:441:in `fetch'
      # ./lib/fontist/update.rb:43:in `update_main_repo'
      # ./lib/fontist/update.rb:12:in `call'
      # ./spec/fontist/update_spec.rb:105:in `block (6 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:414:in `block in formula_repo_with'
      # ./spec/support/fontist_helper.rb:407:in `formula_repo_with'
      # ./spec/fontist/update_spec.rb:102:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/fontist/update_spec.rb:98:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:97:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```