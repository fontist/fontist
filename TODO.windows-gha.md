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

       (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108-5040-35hzc9/fonts/andale/AndaleMo.TTF"]}}})
           expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108-5040-35hzc9/fonts/andale/AndaleMo.TTF"]}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:692:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  5) Fontist::CLI#manifest_locations contains one font with bold style returns font location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(output)

       (Fontist::Utils::UI (class)).say(include yaml {"Courier New"=>{"Bold"=>{"full_name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-x1cf3o/fonts/courbd/courbd.ttf"]}}})
           expected: 1 time with arguments: (include yaml {"Courier New"=>{"Bold"=>{"full_name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-x1cf3o/fonts/courbd/courbd.ttf"]}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:711:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  6) Fontist::CLI#manifest_locations contains two fonts returns font location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(output)

       (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108..._name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-eo9aut/fonts/courbd/courbd.ttf"]}}})
           expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>["D:/a/_temp/d20260108..._name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-eo9aut/fonts/courbd/courbd.ttf"]}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:739:in `block (5 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  7) Fontist::CLI#manifest_install installed font returns its location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

       (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>[include "AndaleMo.TTF"]}}})
           expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>[include "AndaleMo.TTF"]}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  8) Fontist::CLI#manifest_install supported and installed by system font returns its location
     Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

       (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include (include "AndaleMo.TTF")}}})
           expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include (include "AndaleMo.TTF")}}})
           received: 0 times
     # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
     # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  9) Fontist::CLI#manifest_install not installed but supported font installs font file
     Failure/Error:
       expect { command }
         .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)

       expected `font_file("AndaleMo.TTF").exist?` to have changed from false to true, but did not change
     # ./spec/fontist/cli_spec.rb:933:in `block (4 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  10) Fontist::CLI#manifest_install not installed but supported font returns its location
      Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

        (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF/i}}})
            expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF/i}}})
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  11) Fontist::CLI#manifest_install two supported fonts installs both and returns their locations
      Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

        (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF...name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-mnwqeb/fonts/courier/courbd.ttf"]}}})
            expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF...name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d20260108-5040-mnwqeb/fonts/courier/courbd.ttf"]}}})
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  12) Fontist::CLI#manifest_install not installed, one supported, one unsupported tells that font is unsupported
      Failure/Error: expect(Fontist.ui).to receive(:error).with(/Font 'Unexisting Font' not found locally nor/)

        (Fontist::Utils::UI (class)).error(/Font 'Unexisting Font' not found locally nor/)
            expected: 1 time with arguments: (/Font 'Unexisting Font' not found locally nor/)
            received: 0 times
      # ./spec/fontist/cli_spec.rb:976:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  13) Fontist::CLI#manifest_install with no style specified installs supported and returns its location and no location
      Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

        (Fontist::Utils::UI (class)).say(include yaml {"Georgia"=>{"Bold"=>{"full_name"=>"Georgia Bold", "paths"=>include /Georgiab\.TTF/i}, "...=>include /Georgiai\.TTF/i}, "Regular"=>{"full_name"=>"Georgia", "paths"=>include /Georgia\.TTF/i}}})
            expected: 1 time with arguments: (include yaml {"Georgia"=>{"Bold"=>{"full_name"=>"Georgia Bold", "paths"=>include /Georgiab\.TTF/i}, "...=>include /Georgiai\.TTF/i}, "Regular"=>{"full_name"=>"Georgia", "paths"=>include /Georgia\.TTF/i}}})
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  14) Fontist::CLI#manifest_install with no style by font name from formulas installs both and returns their locations
      Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

        (Fontist::Utils::UI (class)).say(include yaml {"Courier New"=>{"Bold"=>{"full_name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d202601...>{"full_name"=>"Courier New", "paths"=>["D:/a/_temp/d20260108-5040-m250z/fonts/courier/cour.ttf"]}}})
            expected: 1 time with arguments: (include yaml {"Courier New"=>{"Bold"=>{"full_name"=>"Courier New Bold", "paths"=>["D:/a/_temp/d202601...>{"full_name"=>"Courier New", "paths"=>["D:/a/_temp/d20260108-5040-m250z/fonts/courier/cour.ttf"]}}})
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  15) Fontist::CLI#manifest_install confirmed license in cli option installs font file
      Failure/Error:
        expect { command }
          .to change { font_file("AndaleMo.TTF").exist? }.from(false).to(true)

        expected `font_file("AndaleMo.TTF").exist?` to have changed from false to true, but did not change
      # ./spec/fontist/cli_spec.rb:1049:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  16) Fontist::CLI#manifest_install confirmed license in cli option returns its location
      Failure/Error: expect(Fontist.ui).to receive(:say).with(include_yaml(result))

        (Fontist::Utils::UI (class)).say(include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF/i}}})
            expected: 1 time with arguments: (include yaml {"Andale Mono"=>{"Regular"=>{"full_name"=>"Andale Mono", "paths"=>include /AndaleMo\.TTF/i}}})
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1196:in `expect_say_yaml'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  17) Fontist::CLI#manifest_install with accept flag, no hide-licenses flag still shows license text
      Failure/Error: expect(Fontist.ui).to receive(:say).with(/^FONT LICENSE ACCEPTANCE/)

        (Fontist::Utils::UI (class)).say(/^FONT LICENSE ACCEPTANCE/)
            expected: 1 time with arguments: (/^FONT LICENSE ACCEPTANCE/)
            received: 0 times
      # ./spec/fontist/cli_spec.rb:1087:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  18) Fontist::CLI#manifest_install with --location option valid locations accepts --location=fontist
      Failure/Error: expect(command).to be 0

        expected #<Integer:1> => 0
             got #<Integer:11> => 5

        Compared using equal?, which compares object identity,
        but expected and actual are not the same object. Use
        `expect(actual).to eq(expected)` if you don't care about
        object identity in this example.
      # ./spec/fontist/cli_spec.rb:1114:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  19) Fontist::Config options fonts_path fonts install path is specified in config installs fonts in that dir
      Failure/Error: expect(command.first).to start_with(dir)
        expected "D:/a/_temp/d20260108-5040-2364t8/andale/AndaleMo.TTF" to start with "D:/a/_temp/d20260108-5040-v3kqba"
      # ./spec/fontist/config_spec.rb:50:in `block (6 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:516:in `block in safe_mktmpdir'
      # ./spec/support/fontist_helper.rb:515:in `safe_mktmpdir'
      # ./spec/fontist/config_spec.rb:45:in `block (5 levels) in <top (required)>'
      # ./spec/fontist/config_spec.rb:35:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  20) Fontist::FontInstaller#install first mirror fails tries the second one
      Failure/Error:
        expect(Down).to receive(:download)
          .with(first_mirror, any_args).and_raise(Down::NotFound, "not found")
          .at_least(3).times

        (Down).download("https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe", *(any args))
            expected: at least 3 times with arguments: ("https://gitlab.com/fontmirror/archive/-/raw/master/andale32.exe", *(any args))
            received: 0 times
      # ./spec/fontist/font_installer_spec.rb:51:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  21) Fontist::Font.find with windows user fonts returns user's path
      Failure/Error: raise Fontist::Errors::UnsupportedFontError.new(@name)

      Fontist::Errors::UnsupportedFontError:
        Font 'dejavu serif' not found locally nor available in the Fontist formula repository.
        Perhaps it is available at the latest Fontist formula repository.
        You can update the formula repository using the command `fontist update` and try again.
      # ./lib/fontist/font.rb:463:in `raise_non_supported_font'
      # ./lib/fontist/font.rb:67:in `find'
      # ./lib/fontist/font.rb:32:in `find'
      # ./spec/fontist/font_spec.rb:15:in `block (3 levels) in <top (required)>'
      # ./spec/fontist/font_spec.rb:129:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  22) Fontist::Font.install not installed but supported prints descriptive messages of what's going on
      Failure/Error: expect(Fontist.ui).to receive(:say).with(%(Font "andale mono" not found locally.))

        (Fontist::Utils::UI (class)).say("Font \"andale mono\" not found locally.")
            expected: 1 time with arguments: ("Font \"andale mono\" not found locally.")
            received: 0 times
      # ./spec/fontist/font_spec.rb:233:in `block (4 levels) in <top (required)>'
      # ./spec/fontist/font_spec.rb:229:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:479:in `block in avoid_cache'
      # ./spec/support/fontist_helper.rb:474:in `avoid_cache'
      # ./spec/fontist/font_spec.rb:229:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  23) Fontist::Font.install with --no-progress option skips printing of progress lines
      Failure/Error: expect(Fontist.ui).to receive(:print).with(/\r\e\[0KDownloading:/).once

        (Fontist::Utils::UI (class)).print(/\r\e\[0KDownloading:/)
            expected: 1 time with arguments: (/\r\e\[0KDownloading:/)
            received: 0 times
      # ./spec/fontist/font_spec.rb:256:in `block (4 levels) in <top (required)>'
      # ./spec/fontist/font_spec.rb:253:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:479:in `block in avoid_cache'
      # ./spec/support/fontist_helper.rb:474:in `avoid_cache'
      # ./spec/fontist/font_spec.rb:253:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  24) Fontist::Font.install not installed but supported and in cache tells about fetching from cache
      Failure/Error:
        expect(Fontist.ui)
          .to receive(:say).with("Using cached file.")

        (Fontist::Utils::UI (class)).say("Using cached file.")
            expected: 1 time with arguments: ("Using cached file.")
            received: 0 times
      # ./spec/fontist/font_spec.rb:270:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  25) Fontist::Font.install already installed font tells that font found locally
      Failure/Error: expect(Fontist.ui).to receive(:say).with(%(Fonts found at:))

        (Fontist::Utils::UI (class)).say("Fonts found at:")
            expected: 1 time with arguments: ("Fonts found at:")
            received: 0 times
      # ./spec/fontist/font_spec.rb:281:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  26) Fontist::Font.install with subdir option installs from proper directory
      Failure/Error: expect(font_file(file).size).to eq current_version_size

      Errno::ENOENT:
        No such file or directory @ rb_file_s_size - D:/a/_temp/d20260108-5040-w2ztwi/fonts/WorkSans-Regular.ttf
      # ./spec/fontist/font_spec.rb:388:in `size'
      # ./spec/fontist/font_spec.rb:388:in `size'
      # ./spec/fontist/font_spec.rb:388:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  27) Fontist::Font.install with force flag when installed installs font anyway
      Got 7 failures:

      27.1) Failure/Error: expect(font_file(file)).not_to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-n2xo7a/fonts/andale/AndaleMo.TTF> not to exist
            # ./spec/fontist/font_spec.rb:402:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.2) Failure/Error: expect(font_file(file)).not_to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-n2xo7a/fonts/andale/AndaleMo.TTF> not to exist
            # ./spec/fontist/font_spec.rb:402:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.3) Failure/Error: expect(font_file(file)).not_to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-n2xo7a/fonts/andale/AndaleMo.TTF> not to exist
            # ./spec/fontist/font_spec.rb:402:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.4) Failure/Error: expect(font_file(file)).to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-jsy2cy/fonts/AndaleMo.TTF> to exist
            # ./spec/fontist/font_spec.rb:404:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.5) Failure/Error: expect(font_file(file)).to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-jsy2cy/fonts/AndaleMo.TTF> to exist
            # ./spec/fontist/font_spec.rb:404:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.6) Failure/Error: expect(font_file(file)).to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-jsy2cy/fonts/AndaleMo.TTF> to exist
            # ./spec/fontist/font_spec.rb:404:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

      27.7) Failure/Error: expect(font_file(file)).to exist
              expected #<Pathname:D:/a/_temp/d20260108-5040-jsy2cy/fonts/AndaleMo.TTF> to exist
            # ./spec/fontist/font_spec.rb:404:in `block (4 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/system_fonts.rb:7:in `block (2 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
            # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
            # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  28) Fontist::Font.install with unusual font extension detects, renames and installs the font
      Failure/Error: expect(font_file(file)).to exist
        expected #<Pathname:D:/a/_temp/d20260108-5040-r8088z/fonts/adobedevanagari_bolditalic.otf> to exist
      # ./spec/fontist/font_spec.rb:415:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  29) Fontist::Font.install with set FONTIST_PATH env installs font at a FONTIST_PATH directory
      Failure/Error:
        expect(Pathname.new(File.join(fontist_path, "fonts", "andale", file)))
          .to exist

        expected #<Pathname:D:/a/_temp/d20260108-5040-iwqa7y/fonts/andale/AndaleMo.TTF> to exist
      # ./spec/fontist/font_spec.rb:432:in `block (7 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:399:in `block in rebuilt_index'
      # ./spec/support/fontist_helper.rb:393:in `rebuilt_index'
      # ./spec/fontist/font_spec.rb:430:in `block (6 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:456:in `stub_env'
      # ./spec/fontist/font_spec.rb:426:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:516:in `block in safe_mktmpdir'
      # ./spec/support/fontist_helper.rb:515:in `safe_mktmpdir'
      # ./spec/fontist/font_spec.rb:425:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  30) Fontist::Font.install preferred family with option does not find by default family
      Failure/Error:
        expect { command }
          .to raise_error(Fontist::Errors::UnsupportedFontError)

        expected Fontist::Errors::UnsupportedFontError but nothing was raised
      # ./spec/fontist/font_spec.rb:467:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:491:in `with_option'
      # ./spec/fontist/font_spec.rb:466:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  31) Fontist::Font.install has min_fontist attribute higher min_fontist throws FontistVersionError
      Failure/Error: expect { command }.to raise_error Fontist::Errors::FontistVersionError
        expected Fontist::Errors::FontistVersionError but nothing was raised
      # ./spec/fontist/font_spec.rb:506:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  32) Fontist::Font.install has min_fontist attribute higher min_fontist, above size limit raises size-limit error
      Failure/Error: expect { command }.to raise_error(Fontist::Errors::SizeLimitError)
        expected Fontist::Errors::SizeLimitError but nothing was raised
      # ./spec/fontist/font_spec.rb:521:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  33) Fontist::Font.install has min_fontist attribute higher min_fontist, missing version raises font unsupported error
      Failure/Error:
        expect { command }
          .to raise_error Fontist::Errors::UnsupportedFontError

        expected Fontist::Errors::UnsupportedFontError but nothing was raised
      # ./spec/fontist/font_spec.rb:531:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  34) Fontist::Font.install two formulas with the same font both size below the limit, diff versions installs the newest
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  35) Fontist::Font.install two formulas with the same font both size below the limit, same versions installs the smallest
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  36) Fontist::Font.install two formulas with the same font size above the limit raises size-limit error
      Failure/Error: expect { command }.to raise_error(Fontist::Errors::SizeLimitError)
        expected Fontist::Errors::SizeLimitError but nothing was raised
      # ./spec/fontist/font_spec.rb:624:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  37) Fontist::Font.install two formulas with the same font formula has no file_size and size limit is very low install the formula anyway
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  38) Fontist::Font.install two formulas with the same font concrete version is passed installs formula with this version
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  39) Fontist::Font.install two formulas with the same font concrete version is the smallest in a formula installs formula with this version
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  40) Fontist::Font.install two formulas with the same font concrete version is passed and there is no such raises font unsupported error
      Failure/Error:
        expect { command }
          .to raise_error Fontist::Errors::UnsupportedFontError

        expected Fontist::Errors::UnsupportedFontError but nothing was raised
      # ./spec/fontist/font_spec.rb:695:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  41) Fontist::Font.install two formulas with the same font requested to install the smallest installs the smallest formula
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  42) Fontist::Font.install two formulas with the same font requested to install the newest installs the newest formula
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  43) Fontist::Font.install two formulas with the same font with user-defined size limit installs a formula below the size limit
      Failure/Error: example.run
        Exactly one instance should have received the following message(s) but didn't: font_installer
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  44) Fontist::Font.install two formulas with the same font with update_fontconfig option set to true calls Fontconfig
      Failure/Error: expect(Fontist::Fontconfig).to receive(:update)

        (Fontist::Fontconfig (class)).update(*(any args))
            expected: 1 time with any arguments
            received: 0 times with any arguments
      # ./spec/fontist/font_spec.rb:755:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  45) Fontist::Font.install two formulas with the same font with location parameter invalid locations shows error for invalid symbol but proceeds with default
      Failure/Error: expect(Fontist.ui).to receive(:error).with(include("Invalid install location"))

        (Fontist::Utils::UI (class)).error(include "Invalid install location")
            expected: 1 time with arguments: (include "Invalid install location")
            received: 0 times
      # ./spec/fontist/font_spec.rb:796:in `block (6 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  46) Fontist::Font.install two formulas with the same font with location parameter location option passed through properly passes location to FontInstaller
      Failure/Error:
        expect(Fontist::InstallLocation).to receive(:create)
          .with(anything, hash_including(location_type: :user))
          .and_call_original

        (Fontist::InstallLocation (class)).create(anything, hash_including(:location_type=>:user))
            expected: 1 time with arguments: (anything, hash_including(:location_type=>:user))
            received: 0 times
      # ./spec/fontist/font_spec.rb:823:in `block (6 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  47) Fontist::Font.install with no setup no main repo throws MainRepoNotFoundError
      Failure/Error:
        expect { command }
          .to raise_error(Fontist::Errors::MainRepoNotFoundError)

        expected Fontist::Errors::MainRepoNotFoundError, got #<Fontist::Errors::UnsupportedFontError: Font 'any font' not found locally nor available in the Fonti...repository.
        You can update the formula repository using the command `fontist update` and try again.> with backtrace:
          # ./lib/fontist/font.rb:463:in `raise_non_supported_font'
          # ./lib/fontist/font.rb:74:in `install'
          # ./lib/fontist/font.rb:36:in `install'
          # ./spec/fontist/font_spec.rb:869:in `block (3 levels) in <top (required)>'
          # ./spec/fontist/font_spec.rb:879:in `block (5 levels) in <top (required)>'
          # ./spec/fontist/font_spec.rb:879:in `block (4 levels) in <top (required)>'
          # ./spec/support/empty_home.rb:10:in `block (3 levels) in <top (required)>'
          # ./spec/support/empty_home.rb:7:in `block (2 levels) in <top (required)>'
          # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
      # ./spec/fontist/font_spec.rb:879:in `block (4 levels) in <top (required)>'
      # ./spec/support/empty_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/empty_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  48) Fontist::Font.uninstall with supported font but not installed raises font missing error
      Failure/Error: expect { command }.to raise_error Fontist::Errors::MissingFontError
        expected Fontist::Errors::MissingFontError but nothing was raised
      # ./spec/fontist/font_spec.rb:917:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:29:in `block in fresh_fonts_and_formulas'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:23:in `fresh_fonts_and_formulas'
      # ./spec/fontist/font_spec.rb:912:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  49) Fontist::Font.list differing platforms does not contain the formula
      Failure/Error: expect(formulas).to eq []

        expected: []
             got: ["andale", "au", "au_passata_oblique", "cleartype", "courier", "lato", "manual", "overpass", "source"...ex_gyre_chorus", "tex_gyre_chorus_min_fontist_1", "tex_gyre_chorus_min_fontist_and_font", "webcore"]

        (compared using ==)
      # ./spec/fontist/font_spec.rb:1193:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  50) Fontist::Font.list the same platform returns the formula
      Failure/Error: expect(formulas).to eq ["work_sans_macos_only"]

        expected: ["work_sans_macos_only"]
             got: ["andale", "au", "au_passata_oblique", "cleartype", "courier", "lato", "manual", "overpass", "source"...re_chorus_min_fontist_1", "tex_gyre_chorus_min_fontist_and_font", "webcore", "work_sans_macos_only"]

        (compared using ==)
      # ./spec/fontist/font_spec.rb:1209:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  51) Fontist::FormulaSuggestion#find matching and non-matching formulas finds one
      Failure/Error: expect(subject.count).to be 1

        expected #<Integer:3> => 1
             got #<Integer:5> => 2

        Compared using equal?, which compares object identity,
        but expected and actual are not the same object. Use
        `expect(actual).to eq(expected)` if you don't care about
        object identity in this example.
      # ./spec/fontist/formula_suggestion_spec.rb:73:in `block (4 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  52) Fontist::Manifest install .from_hash requires license confirmation and no flag passed raises licensing error
      Failure/Error: expect { instance }.to raise_error Fontist::Errors::LicensingError
        expected Fontist::Errors::LicensingError but nothing was raised
      # ./spec/fontist/manifest_spec.rb:72:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  53) Fontist::Manifest install .from_hash confirmation option passed as no and nil input is returned raises licensing error
      Failure/Error: expect { instance }.to raise_error Fontist::Errors::LicensingError
        expected Fontist::Errors::LicensingError but nothing was raised
      # ./spec/fontist/manifest_spec.rb:83:in `block (5 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  54) Fontist::Manifest install .from_hash with location parameter invalid locations shows error for invalid location but proceeds
      Failure/Error: expect(Fontist.ui).to receive(:error).with(include("Invalid install location"))

        #<Fontist::Utils::UI (class)> received :error with unexpected arguments
          expected: (include "Invalid install location")
               got: ("#<Fontist::Errors::FontFileError: Font file could not be parsed: #<Fontisan::InvalidFontError: Unkno...Warning: File at D:/a/_temp/d20260108-5040-iwqa7y/fonts/AndaleMo.TTF not recognized as a font file.") (5 times)
      # ./spec/fontist/manifest_spec.rb:144:in `block (6 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  55) Fontist::Manifest install .from_hash with location parameter location applied to all fonts passes location to each font installation
      Failure/Error:
        expect(Fontist::Font).to receive(:install)
          .with("Andale Mono", hash_including(location: :user))
          .and_call_original

        (Fontist::Font (class)).install("Andale Mono", hash_including(:location=>:user))
            expected: 1 time with arguments: ("Andale Mono", hash_including(:location=>:user))
            received: 0 times
      # ./spec/fontist/manifest_spec.rb:173:in `block (6 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
      # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  56) Fontist::RepoCLI#update no such repo prints error message and returns not-found status
      Failure/Error: handle_git_error(name, git.config["remote.origin.url"], e, :update)

      NoMethodError:
        undefined method `config' for nil:NilClass

                  handle_git_error(name, git.config["remote.origin.url"], e, :update)

                                            ^^^^^^^
      # ./lib/fontist/repo.rb:114:in `rescue in update'
      # ./lib/fontist/repo.rb:101:in `update'
      # ./lib/fontist/repo_cli.rb:24:in `update'
      # ./vendor/bundle/ruby/3.1.0/gems/thor-1.5.0/lib/thor/command.rb:28:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/thor-1.5.0/lib/thor/invocation.rb:127:in `invoke_command'
      # ./vendor/bundle/ruby/3.1.0/gems/thor-1.5.0/lib/thor.rb:538:in `dispatch'
      # ./vendor/bundle/ruby/3.1.0/gems/thor-1.5.0/lib/thor/base.rb:585:in `start'
      # ./spec/fontist/repo_cli_spec.rb:70:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
      # ------------------
      # --- Caused by: ---
      # ArgumentError:
      #   'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/Formulas/private/acme' is not in a git working tree
      #   ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:101:in `root_of_worktree'

  57) Fontist::RepoCLI#remove no such repo prints error message and returns not-found status
      Failure/Error: expect(status).to be Fontist::CLI::STATUS_REPO_NOT_FOUND

        expected #<Integer:17> => 8
             got #<Integer:1> => 0

        Compared using equal?, which compares object identity,
        but expected and actual are not the same object. Use
        `expect(actual).to eq(expected)` if you don't care about
        object identity in this example.
      # ./spec/fontist/repo_cli_spec.rb:119:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  58) Fontist::Repo#list private repo exists returns a list of repo names
      Failure/Error: expect(described_class.list).to eq %w[acme]

        expected: ["acme"]
             got: ["acme", "test"]

        (compared using ==)
      # ./spec/fontist/repo_spec.rb:200:in `block (6 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:414:in `block in formula_repo_with'
      # ./spec/support/fontist_helper.rb:407:in `formula_repo_with'
      # ./spec/fontist/repo_spec.rb:193:in `block (5 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/repo_spec.rb:192:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  59) Fontist::SystemIndex two simultaneous runs generates the same system index
      Failure/Error: expect(File.read(test_index_path)).to eq(File.read(reference_index_path))

      Errno::ENOENT:
        No such file or directory @ rb_sysopen - D:/a/_temp/d20260108-5040-vedafy/system_index.yml
      # ./spec/fontist/system_index_spec.rb:33:in `read'
      # ./spec/fontist/system_index_spec.rb:33:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  60) Fontist::Update no main repo creates main repo
      Failure/Error: git.fetch

      Git::FailedError:
        [{"GIT_DIR"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git", "GIT_WORK_TREE"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas", "GIT_INDEX_FILE"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git/index", "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "--git-dir=D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git", "--work-tree=D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "fetch", "--", "origin"], status: pid 2824 exit 128, stderr: "fatal: unable to access 'https://github.com/fontist/formulas.git/': getaddrinfo() thread failed to start"
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1344:in `fetch'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:441:in `fetch'
      # ./lib/fontist/update.rb:43:in `update_main_repo'
      # ./lib/fontist/update.rb:12:in `call'
      # ./lib/fontist/update.rb:4:in `call'
      # ./spec/fontist/update_spec.rb:9:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:8:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  61) Fontist::Update main repo exists doesn't fail
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260108-5040-x6ip61", "D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas"], status: pid 3604 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas' already exists and is not an empty directory."
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:141:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:24:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git.rb:196:in `clone'
      # ./spec/support/fontist_helper.rb:94:in `block in fresh_main_repo'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:18:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:17:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  62) Fontist::Update main repo changed branch fetches changes
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260108-5040-jhyx0k", "D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas"], status: pid 8636 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas' already exists and is not an empty directory."
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:141:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:24:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git.rb:196:in `clone'
      # ./spec/support/fontist_helper.rb:94:in `block in fresh_main_repo'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:31:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:30:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  63) Fontist::Update main repo updated on changed branch fetches changes
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260108-5040-5x9u2g", "D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas"], status: pid 6616 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas' already exists and is not an empty directory."
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:141:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:24:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git.rb:196:in `clone'
      # ./spec/support/fontist_helper.rb:94:in `block in fresh_main_repo'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:53:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:52:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  64) Fontist::Update private repo has new formula makes so fontist can find fonts from the formula
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260108-5040-ijg3rx", "D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas"], status: pid 2968 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas' already exists and is not an empty directory."
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:141:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:24:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git.rb:196:in `clone'
      # ./spec/support/fontist_helper.rb:94:in `block in fresh_main_repo'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:69:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:68:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  65) Fontist::Update private repo's branch is main instead of master runs successfully
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260108-5040-cej7h0", "D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas"], status: pid 7208 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas' already exists and is not an empty directory."
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:241:in `block in process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:238:in `process_result'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/command_line.rb:199:in `run'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:1630:in `command'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/lib.rb:141:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git/base.rb:24:in `clone'
      # ./vendor/bundle/ruby/3.1.0/gems/git-3.1.1/lib/git.rb:196:in `clone'
      # ./spec/support/fontist_helper.rb:94:in `block in fresh_main_repo'
      # ./spec/support/fontist_helper.rb:109:in `block in remote_main_repo'
      # ./spec/support/fontist_helper.rb:101:in `remote_main_repo'
      # ./spec/support/fontist_helper.rb:93:in `fresh_main_repo'
      # ./spec/fontist/update_spec.rb:85:in `block (4 levels) in <top (required)>'
      # ./spec/support/fontist_helper.rb:69:in `block in fresh_fontist_home'
      # ./spec/support/fontist_helper.rb:50:in `fresh_fontist_home'
      # ./spec/fontist/update_spec.rb:84:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  66) Fontist::Update private repo is set up before the main one fetches the main repo
      Failure/Error: git.fetch

      Git::FailedError:
        [{"GIT_DIR"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git", "GIT_WORK_TREE"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas", "GIT_INDEX_FILE"=>"D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git/index", "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "--git-dir=D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas/.git", "--work-tree=D:/a/_temp/d20260108-5040-iwqa7y/versions/v4/formulas", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "fetch", "--", "origin"], status: pid 1496 exit 128, stderr: "fatal: unable to access 'https://github.com/fontist/formulas.git/': getaddrinfo() thread failed to start"
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

