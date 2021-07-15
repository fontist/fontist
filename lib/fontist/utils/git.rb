require "git"

module Fontist
  module Utils
    class Git
      def self.clone(url, path, opts)
        http_proxy = ENV["SOCKS_PROXY"] || ENV["HTTP_PROXY"]
        https_proxy = ENV["SOCKS_PROXY"] || ENV["HTTPS_PROXY"]
        if http_proxy || https_proxy
          clone_with_proxy(http_proxy, https_proxy, url, path, opts)
        else
          ::Git.clone(url, path, opts)
        end
      end

      def self.clone_with_proxy(http_proxy, https_proxy, url, path, _opts)
        git = Git.init(path.to_s)
        # NOTE what if user move out of proxy?
        git.config("http.proxy", http_proxy) if http_proxy
        git.config("https.proxy", https_proxy) if https_proxy
        git.add_remote("origin", url)
        git.fetch
        git.checkout("master") # FIXME after https://github.com/ruby-git/ruby-git/pull/532
        path
      end
    end
  end
end
