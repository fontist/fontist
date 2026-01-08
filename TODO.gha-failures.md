Failed on macos:

```
Failures:

  1) Fontist::CLI#list no font specified returns success status and prints list with no installed status
     Failure/Error: expect(Fontist.ui).to receive(:error).at_least(1).times

       (Fontist::Utils::UI (class)).error(*(any args))
           expected: at least 1 time with any arguments
           received: 0 times with any arguments
     # ./spec/fontist/cli_spec.rb:595:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  2) Fontist::Font.list with no font and nothing installed returns all fonts
     Failure/Error: expect(command.size).to be > 1

       expected: > 1
            got:   0
     # ./spec/fontist/font_spec.rb:1142:in `block (5 levels) in <top (required)>'
     # ./spec/support/fontist_helper.rb:163:in `stub_fonts_path_to_new_path'
     # ./spec/fontist/font_spec.rb:1141:in `block (4 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

Failed on ubuntu:

```

Failures:

  1) Fontist::CLI#status supported and installed font returns success status and prints path
     Failure/Error: expect(status).to be 0

       expected #<Integer:1> => 0
            got #<Integer:5> => 2

       Compared using equal?, which compares object identity,
       but expected and actual are not the same object. Use
       `expect(actual).to eq(expected)` if you don't care about
       object identity in this example.
     # ./spec/fontist/cli_spec.rb:500:in `block (5 levels) in <top (required)>'
     # ./spec/support/fontist_helper.rb:163:in `stub_fonts_path_to_new_path'
     # ./spec/fontist/cli_spec.rb:495:in `block (4 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  2) Fontist::CLI#status supported and installed font shows formula and font names
     Failure/Error: expect(Fontist.ui).to receive(:say).with(/^- .*AndaleMo.TTF \(from andale formula\)$/)

       #<Fontist::Utils::UI (class)> received :say with unexpected arguments
         expected: (/^- .*AndaleMo.TTF \(from andale formula\)$/)
              got: ("Font \"andale mono\" not found locally.")
       Diff:
       @@ -1 +1 @@
       -[/^- .*AndaleMo.TTF \(from andale formula\)$/]
       +["Font \"andale mono\" not found locally."]
     # ./spec/fontist/cli_spec.rb:509:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  3) Fontist::CLI#status collection font prints its formula
     Failure/Error: expect(status).to be 0

       expected #<Integer:1> => 0
            got #<Integer:7> => 3

       Compared using equal?, which compares object identity,
       but expected and actual are not the same object. Use
       `expect(actual).to eq(expected)` if you don't care about
       object identity in this example.
     # ./spec/fontist/cli_spec.rb:534:in `block (5 levels) in <top (required)>'
     # ./spec/support/fontist_helper.rb:29:in `block in fresh_fonts_and_formulas'
     # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
     # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
     # ./spec/support/fontist_helper.rb:23:in `fresh_fonts_and_formulas'
     # ./spec/fontist/cli_spec.rb:527:in `block (4 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  4) Fontist::CLI#list supported and installed font prints `installed`
     Failure/Error: expect(Fontist.ui).to receive(:success).with(include("(installed)"))

      # ./spec/support/fontist_helper.rb:23:in `fresh_fonts_and_formulas'
      # ./spec/fontist/font_spec.rb:1126:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  17) Fontist::Font.list with no font and nothing installed returns all fonts
      Failure/Error: expect(command.size).to be > 1

        expected: > 1
             got:   0
      # ./spec/fontist/font_spec.rb:1142:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:163:in `stub_fonts_path_to_new_path'
      # ./spec/fontist/font_spec.rb:1141:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  18) Fontist::Font.list with no font and a font installed returns installed font with its path
      Failure/Error: expect(statuses).to include(true)

        expected [false, false, false, false, false] to include true
        Diff:
        @@ -1 +1 @@
        -[true]
        +[false, false, false, false, false]
      # ./spec/fontist/font_spec.rb:1168:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:29:in `block in fresh_fonts_and_formulas'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:23:in `fresh_fonts_and_formulas'
      # ./spec/fontist/font_spec.rb:1154:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  19) Fontist::Manifest install .from_hash with location parameter invalid locations shows error for invalid location but proceeds
      Failure/Error: expect(result).to be_a(Fontist::ManifestResponse)
        expected #<Fontist::Manifest:0x00007f831f2fba08 @using_default={}, @__register=:default, @fonts=[#<Fontist::Ma...ault={:name=>false, :styles=>false}, @__register=:default, @name="Andale Mono", @styles="Regular">]> to be a kind of Fontist::ManifestResponse
      # ./spec/fontist/manifest_spec.rb:147:in `block (6 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  20) Fontist::SystemFont.find with valid font name returns the complete font path
      Failure/Error: expect(paths).to include(include("CAMBRIA.TTC"))
        expected nil to include (include "CAMBRIA.TTC"), but it does not respond to `include?`
      # ./spec/fontist/system_font_spec.rb:23:in `block (6 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:181:in `stub_system_fonts_path_to_new_path'
      # ./spec/support/fontist_helper.rb:133:in `block in no_fonts'
      # ./spec/support/fontist_helper.rb:163:in `stub_fonts_path_to_new_path'
      # ./spec/support/fontist_helper.rb:132:in `no_fonts'
      # ./spec/fontist/system_font_spec.rb:19:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:466:in `stub_system_index_path'
      # ./spec/fontist/system_font_spec.rb:18:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

Windows is hung by "Overwrite?" message!!

```
Fontist::Repo
  #setup
    setups repo and lets find its formulas
    invalid URL
      raises error with helpful message
    non-existent repository
DEPRECATION WARNING: Git::GitExecuteError is deprecated! Use Git::Error instead. (called from block (5 levels) in <top (required)> at D:/a/fontist/fontist/spec/fontist/repo_spec.rb:28)
      raises appropriate error
    authentication required
DEPRECATION WARNING: Git::GitExecuteError is deprecated! Use Git::Error instead. (called from block (5 levels) in <top (required)> at D:/a/fontist/fontist/spec/fontist/repo_spec.rb:41)
      raises error with credential configuration instructions
    repo already exists
      prompts for overwrite and cancels when user says no
      prompts for overwrite and proceeds when user says yes
    duplicate URL detection
      prevents setting up repo with same URL under different name
      allows same name with same URL (overwrite scenario)
      normalizes URLs correctly for comparison
  #update
    no such repo
      throws not-found error
    repo exists
      updates existing repo and lets find new formulas
  #remove
    no such repo
      throws not-found error
    repo exists
      removes existing repo, and its formulas cannot be found anymore
  #list
    private repo exists
rake aborted!
Interrupt:
D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/rspec-core-3.13.6/lib/rspec/core/rake_task.rb:99:in `system'
D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/rspec-core-3.13.6/lib/rspec/core/rake_task.rb:99:in `run_task'
D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/rspec-core-3.13.6/lib/rspec/core/rake_task.rb:118:in `block (2 levels) in define'
D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/rspec-core-3.13.6/lib/rspec/core/rake_task.rb:116:in `block in define'
D:/a/fontist/fontist/vendor/bundle/ruby/3.1.0/gems/rake-13.3.1/exe/rake:27:in `<top (required)>'
Tasks: TOP => default => spec
(See full trace by running task with --trace)

RSpec is shutting down and will print the summary report... Interrupt again to force quit (warning: at_exit hooks will be skipped if you force quit).
Do you want to overwrite it? [y/N]
```