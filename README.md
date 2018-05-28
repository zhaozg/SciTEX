SciTEX
======
SciTE with eXtensions for Windows/MacOS

[![Build status](https://ci.appveyor.com/api/projects/status/g23g51quxjrqhggu/branch/master?svg=true)](https://ci.appveyor.com/project/zhaozg/scitex/branch/master)

A Favorite editor for dynamic or script language, simultaneously suitable for general text processing.

## Build

### Buiding on MacOS

install gtk+ use homebrew

```
brew install gtk
```

checkout SciTEX sourcode

```
git clone https://github.com/zhaozg/SciTEX.git
cd SciTEX
git submodule init
git submodule update
```

build it
```
cd src/scintilla/gtk
make 
cd ../../scite/gtk
make install
```

Not finished

### Building on Windows

TODO

### Building on Linux

TODO

