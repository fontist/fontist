macOS GHA filaed:

```
Failures:

  1) Fontist::Utils::FileOps.safe_rm_rf on Unix does not retry on errors
     Failure/Error: FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)

     Errno::EACCES:
       Permission denied
     # ./spec/fontist/utils/file_ops_spec.rb:8:in `block (3 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

Ubuntu:
```
Failures:

  1) Fontist::Utils::FileOps.safe_rm_rf on Unix does not retry on errors
     Failure/Error: FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)

     Errno::EACCES:
       Permission denied
     # ./spec/fontist/utils/file_ops_spec.rb:8:in `block (3 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

Windows:

```
Failures:

  1) Fontist::CLI#install with formula option formula from root dir returns success status and prints fonts paths
     Failure/Error: expect(Fontist.ui).to receive(:say).with(match(/AndaleMo\.TTF/i))

       (Fontist::Utils::UI (class)).say(match /AndaleMo\.TTF/i)
           expected: 1 time with arguments: (match /AndaleMo\.TTF/i)
           received: 0 times
     # ./spec/fontist/cli_spec.rb:304:in `block (5 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  2) Fontist::CLI#install with formula option formula from subdir returns success status and prints fonts paths
     Failure/Error: expect(Fontist.ui).to receive(:say).with(match(/AndaleMo\.TTF/i))

       (Fontist::Utils::UI (class)).say(match /AndaleMo\.TTF/i)
           expected: 1 time with arguments: (match /AndaleMo\.TTF/i)
           received: 0 times
     # ./spec/fontist/cli_spec.rb:322:in `block (5 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:7:in `block (2 levels) in <top (required)>'
     # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  3) Fontist::CLI#install with formula option with misspelled formula name suggested formula is chosen installs the formula
     Failure/Error:
       expect(Fontist.ui).to receive(:say)
         .with(match(/texgyrechorus-mediumitalic\.otf/i))

       (Fontist::Utils::UI (class)).say(match /texgyrechorus-mediumitalic\.otf/i)
           expected: 1 time with arguments: (match /texgyrechorus-mediumitalic\.otf/i)
           received: 0 times
     # ./spec/fontist/cli_spec.rb:348:in `block (6 levels) in <top (required)>'
     # ./spec/support/fresh_home.rb:10:in `block (3 levels) in <top (required)>'
  65) Fontist::Update private repo's branch is main instead of master runs successfully
      Failure/Error: Git.clone(dir, Fontist.formulas_repo_path, depth: 1)

      Git::FailedError:
        [{"GIT_DIR"=>nil, "GIT_WORK_TREE"=>nil, "GIT_INDEX_FILE"=>nil, "GIT_SSH"=>nil, "LC_ALL"=>"en_US.UTF-8"}, "git", "-c", "core.quotePath=true", "-c", "color.ui=false", "-c", "color.advice=false", "-c", "color.diff=false", "-c", "color.grep=false", "-c", "color.push=false", "-c", "color.remote=false", "-c", "color.showBranch=false", "-c", "color.status=false", "-c", "color.transport=false", "clone", "--depth", "1", "--", "D:/a/_temp/d20260109-5808-x9tp9y", "D:/a/_temp/d20260109-5808-y5brqc/versions/v4/formulas"], status: pid 2372 exit 128, stderr: "fatal: destination path 'D:/a/_temp/d20260109-5808-y5brqc/versions/v4/formulas' already exists and is not an empty directory."
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

  66) Fontist::Utils::FileOps.safe_rm_rf on Windows raises error after max retries
      Failure/Error: FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)

      Errno::EACCES:
        Permission denied
      # ./spec/fontist/utils/file_ops_spec.rb:8:in `block (3 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  67) Fontist::Utils::FileOps.safe_cp_r on Windows retries on EACCES error
      Failure/Error: expect { described_class.safe_cp_r(src_dir, dest_dir) }.not_to raise_error
        expected no Exception, got #<SystemStackError: stack level too deep> with backtrace:
      # ./spec/fontist/utils/file_ops_spec.rb:187:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'

  68) Fontist::Utils::FileOps.safe_mkdir_p on Windows retries on EACCES error
      Failure/Error: expect { described_class.safe_mkdir_p(new_dir) }.not_to raise_error
        expected no Exception, got #<SystemStackError: stack level too deep> with backtrace:
      # ./spec/fontist/utils/file_ops_spec.rb:216:in `block (4 levels) in <top (required)>'
      # ./vendor/bundle/ruby/3.1.0/gems/webmock-3.26.1/lib/webmock/rspec.rb:39:in `block (2 levels) in <top (required)>'
```

