# Using Fontist with a proxy

Fontist uses Git internally for fetching formulas and fonts.

In order to use Git functionality behind a proxy, you need to update your own
Git config via the `git config` command or the `~/.gitconfig` preference file.

There are many ways to configure your local Git install to use proxies.

The simplest, global way of setting a proxy for Git is the following.

For HTTP

```sh
git config --global http.proxy http://{user}:{pass}@{proxyhost}:{port}
```

For HTTPS, you may need to handle SSL/TLS verification errors after setting
the proxy since the encryption end is located at your HTTPS proxy endpoint:

```sh
git config --global http.proxy https://{user}:{pass}@{proxyhost}:{port}
git config --global https.proxy https://{user}:{pass}@{proxyhost}:{port}
```

For SOCKS, you will need to decide on the SOCKS protocol:

```sh
git config --global http.proxy '{protocol}://{user}:{pass}@{proxyhost}:{port}'
git config --global https.proxy '{protocol}://{user}:{pass}@{proxyhost}:{port}'
```

For example,

```sh
git config --global http.proxy 'socks5h://user:pass@socks-proxy.example.org'
git config --global https.proxy 'socks5h://user:pass@socks-proxy.example.org'
```

The list of supported SOCKS protocols for the `{protocol}` field:

- `socks://`: for SOCKS below v5
- `socks5://`: for SOCKS v5
- `socks5h://`: for SOCKS below v5 + host resolution via SOCKS

You could actually set different proxy behavior for individual Git repositories
— please see this [great guide](https://gist.github.com/evantoli/f8c23a37eb3558ab8765) on how to use Git proxies (thanks to the GitHub user [evantoli](https://github.com/evantoli)).
