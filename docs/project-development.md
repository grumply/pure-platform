Project Development
---

This document describes how to build real-world applications written
in Pure. You will see how to:

- [Create a project from scratch](#creating-the-project)
- [Build it with Nix](#building-with-nix)
- [Develop it incrementally](#building-with-cabal)

Creating the Project
---

First, create a directory for your project. This will contain all of
the files needed for the build process and a checkout of
`pure-platform`, which will provide all of the Haskell libraries and
compilers the project will depend on. To get `pure-platform`, it is
easiest to use [git](https://git-scm.com/) and add it as a submodule,
so that the version being used is consistent amongst your team and
updating it is easy.

```bash
$ mkdir my-project
$ cd my-project
$ git init
$ git submodule add https://github.com/grumply/pure-platform
```

If you've never built a project with `pure-platform` before, you may
need to install [Nix](https://nixos.org/nix/) and configure Pure's
binary cache. `pure-platform` provides the `try-pure` script,
which will do this for you and download some of the basic tools and
libraries we'll need ahead of time.

```bash
$ pure-platform/try-pure
```

After running this command, you'll find yourself in a different
shell. This is the `try-pure` sandbox, which provides GHC and GHCJS
with `pure` preinstalled. You can use this environment to
quickly test things out, but this document only uses it to install
Nix, so go ahead and `exit` out of this shell.

In Pure projects, it's common to have three separate Haskell
components: the frontend, the backend, and the common code shared
between them. It's easiest to have a separate cabal package for each
of these. We're going to teach Nix how to build them and how to give
us an environment where they can be built by hand.

Create a directory for each package, then run `cabal init` inside them
to create the `*.cabal` file and directory structure. If you don't
have `cabal` installed on your system, you can enter the `try-pure`
sandbox to use the version that comes with that. We will see a better
way to get the `cabal` command later.

```bash
$ mkdir common backend frontend
$ (cd common && cabal init)
$ (cd backend && cabal init)
$ (cd frontend && cabal init)
```

This will prompt for various bits of metadata. `common` should be a
library, and `frontend` and `backend` should be executables. These
cabal files are where the dependencies and build targets of each
Haskell component can be described.

In `frontend/frontend.cabal` and `backend/backend.cabal`, add `common`
and `pure` as Haskell dependencies.

```yaml
...
  build-depends: base
               , common
               , pure
...
```

Finally, Nix will fail to build `common` if it exports no modules.

```haskell
-- common/src/Common.hs
module Common where
```

```yaml
...
  exposed-modules: Common
...
```

Building with Nix
---

Nix will be used to manage installing dependencies and building the
project. In the root directory of your project, create this
`default.nix` file:

```nix
# default.nix
(import ./pure-platform {}).project ({ pkgs, ... }: {
  packages = {
    common = ./common;
    backend = ./backend;
    frontend = ./frontend;
  };

  shells = {
    ghc = ["common" "backend" "frontend"];
    ghcjs = ["common" "frontend"];
  };
})
```

See [project/default.nix](../project/default.nix) for more details on
available options.

The `nix-build` command will use this file to build the project.

```bash
$ nix-build
```

This will place a symlink named `result` in the current directory
which points to a directory with all your build products.

```bash
$ tree result
result
├── ghc
│   ├── backend -> /nix/store/{..}-backend-0.1.0.0
│   ├── common -> /nix/store/{..}-common-0.1.0.0
│   └── frontend -> /nix/store/{..}-frontend-0.1.0.0
└── ghcjs
    ├── common -> /nix/store/{..}-common-0.1.0.0
    └── frontend -> /nix/store/{..}-frontend-0.1.0.0
```

You can build individual components of your project using `-A`.

```bash
$ nix-build -o backend-result -A ghc.backend
$ nix-build -o frontend-result -A ghcjs.frontend
```

These commands will create two symlinks (`backend-result` and
`frontend-result`) that point at the build products in the Nix store.

Adding Dependencies
---

Custom dependencies of local libraries can be added via `cabal.project` and `cabal-ghcjs.project`. If you want a backend service, add it to `cabal.project` and `default.nix`, like so:

```yaml
-- cabal.project
allow-newer: all
packages:
  common/
  backend/
  frontend/
  service/ 
```

```nix
# default.nix
{}:

(import ./pure-platform {}).project ({ pkgs, ... }: {
  packages = {
    common = ./common;
    backend = ./backend;
    frontend = ./frontend;
    service = ./service;
  };

  shells = {
    ghc = [ "common" "backend" "frontend" "service" ];
    ghcjs = [ "common" "frontend" ];
  };
})
```

The same can be done for `cabal-ghcjs.project`, but the library would be added to `shells.ghcjs` rather than `shells.ghc`.

If the dependency is available via hackage, but you need an alternate version, you can pin the dependency with `callHackage` using `overrides`, like so:

```nix
# default.nix
{}:

(import ./pure-platform {}).project ({ pkgs, ... }: {

  overrides = self: super: {
    lens = self.callHackage "lens" "4.15.4" {};
  };

  packages = {
    common = ./common;
    backend = ./backend;
    frontend = ./frontend;
  };

  shells = {
    ghc = [ "common" "backend" "frontend" ];
    ghcjs = [ "common" "frontend" ];
  };
})
```

If the dependency is available externally, you can pin it with `fetchWith[..]` using `overrides`, like so:

```nix
# default.nix
{}:

(import ./pure-platform {}).project ({ pkgs, ... }: {

  overrides = self: super: {
    free = self.callCabal2nix "free" (pkgs.fetchFromGitHub {
              owner = "ekmett";
              repo = "free";
              rev = "a0c5bef18b9609377f20ac6a153a20b7b94578c9";
              sha256 = "0vh3hj5rj98d448l647jc6b6q1km4nd4k01s9rajgkc2igigfp6s";
            }) {};
  };

  packages = {
    common = ./common;
    backend = ./backend;
    frontend = ./frontend;
  };

  shells = {
    ghc = [ "common" "backend" "frontend" ];
    ghcjs = [ "common" "frontend" ];
  };
})
```

> Note that pinning the dependency will force all of the packages to use that version; you cannot use one version for `frontend` and another for `backend`.

Another option that simplifies the use of non-hackage dependencies is git submodules. With this approach, you can simply `git pull` changes to the submodule. For example:

```bash
git submodule add -b master https://github.com/grumply/semantic-ui-pure
```

```
-- cabal-ghcjs.project
compiler: ghcjs
allow-newer: all
packages:
  common/
  backend/
  frontend/
  semantic-ui-pure/
```

```nix
# default.nix
{}:

(import ./pure-platform {}).project ({ pkgs, ... }: {
  packages = {
    common = ./common;
    backend = ./backend;
    frontend = ./frontend;
    semantic-ui-pure = ./semantic-ui-pure;
  };

  shells = {
    ghc = [ "common" "backend" "frontend" "semantic-ui-pure" ];
    ghcjs = [ "common" "frontend" "semantic-ui-pure" ];
  };
})
```

And, simply, to update:

```bash
cd semantic-ui-pure
git pull
cd ..
git add semantic-ui-pure
git commit -m 'Update semantic-ui-pure.'
```

Building with Cabal
---

`nix-build` is great for release builds since it's deterministic and
sandboxed, but it is not an incremental build system. Changing one
file will require `nix-build` to recompile the entire package. In
order to get a dev environment where changing a module only rebuilds
the affected modules, even across packages, a more incremental tool is
required.

`cabal` is the only tool that simultaneously supports Nix and
GHCJS. The Nix expression in `default.nix` uses `shells` to setup
`nix-shell` sandboxes that `cabal` can use to build your project. The
`shells` field in `default.nix` defines which platforms we'd like to
develop for, and which packages' dependencies we want available in the
development sandbox for that platform. Note that specifying `common`
is important, otherwise it will be treated as a dependency that needs
to be built by Nix for the sandbox.

You can use these shells with `cabal.project` files to build all three
packages in a shared incremental environment, for both GHC and
GHCJS. `cabal.project` files are how you configure `cabal new-build`
to build your local project. It's easiest to have a separate file for
GHC and GHCJS.

```yaml
-- cabal.project
packages:
  common/
  backend/
  frontend/
```

```yaml
-- cabal-ghcjs.project
compiler: ghcjs
packages:
  common/
  frontend/
```

To build with GHC, use the `nix-shell` command to enter the sandbox
shell and use `cabal` (which is supplied by the sandbox):

```bash
$ nix-shell -A shells.ghc
[nix-shell:~/path]$ cabal new-build all
```

To build with GHCJS:

```bash
$ nix-shell -A shells.ghcjs
[nix-shell:~/path]$ cabal --project-file=cabal-ghcjs.project --builddir=dist-ghcjs new-build all
```

You can also run commands in the nix-shell without entering it
interactively using the `--run` mode. This is useful for scripting.

```bash
$ nix-shell -A shells.ghc --run "cabal new-build all"
$ nix-shell -A shells.ghcjs --run "cabal --project-file=cabal-ghcjs.project --builddir=dist-ghcjs new-build all"
```

`nix-shell` will put you in an environment with all the dependencies
needed by your project, including the `cabal` tool. It reads your
`*.cabal` files to determine what Haskell dependencies to have
installed when you enter the sandbox, so you do not need to manually
run `cabal install` to get Haskell dependencies. Just like Stack, all
you have to do is add them to the `build-depends` field in you cabal
file.

**Note:** Cabal may complain with `Warning: The package list for
'hackage.haskell.org' does not exist. Run 'cabal update' to download
it.` This can be ignored since we are using Nix instead of Cabal's own
package manager. Nix uses a package snapshot similar to a Stackage
LTS.

