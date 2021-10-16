# As a submodule

```
git submodule add https://github.com/Gowa2017/goskynet.git skynetgo
make -C skynetgo LUAINC='path/to/luasource' # or you can use `pwd`/skynet/3rd/lua when skynet is a submodule of you work.
```

# Config

You should make the skynet can find this modules. Set the

lua_cpath, lua_path, luaservice