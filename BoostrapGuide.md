Yang master plan tadi **bisa dipakai sebagai architecture script yang dijalankan lewat executor**, tapi juga bisa dipakai sepenuhnya di Studio/test place. Bedanya cuma **bootstrap / runtime adapter paling bawahnya**.

Konsep entrypoint executor biasanya sederhana: user menjalankan **bootstrap script kecil**, lalu bootstrap itu mengambil source utama dari URL dan mengeksekusinya di runtime client.

Secara konseptual alurnya:

```text
Executor
   ↓
User pastes bootstrap
   ↓
bootstrap fetches source code
   ↓
source code returned as text
   ↓
runtime compiles/executes text
   ↓
main application starts
```

Bentuk yang sering kelihatan kira-kira:

```lua
local source = fetch("https://example.com/main.lua")
execute(source)
```

Di ekosistem executor, fungsi itu sering tampil seperti:

```lua
game:HttpGet(...)
```

untuk mengambil source text, lalu semacam:

```lua
loadstring(source)()
```

untuk mengubah string Lua/Luau tadi menjadi function lalu menjalankannya.

Jadi kalau kelihatan:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/.../loader.lua"))()
```

sebenarnya bisa dibaca sebagai:

```text
1. HTTP GET loader.lua
2. dapat response berupa text
3. compile text tersebut
4. execute hasil compile
```

Kurang lebih analoginya di JavaScript:

```js
const code = await fetch(url).then(r => r.text())
eval(code)
```

Secara engineering, file di GitHub Raw itu biasanya **bukan seluruh aplikasi**. Sering cuma bootstrap/loader.

Misalnya struktur repo:

```text
repo/
├── bootstrap.lua
├── src/
│   ├── main.lua
│   ├── core/
│   ├── adapters/
│   ├── ui/
│   └── features/
└── manifest.json
```

User hanya menjalankan:

```text
bootstrap.lua
```

Lalu bootstrap melakukan:

```text
bootstrap
   ↓
check version
   ↓
download manifest
   ↓
download main/core modules
   ↓
resolve current game
   ↓
load adapter
   ↓
start application
```

Jadi `bootstrap.lua` bisa dianggap seperti:

```text
index.js
main.py
main.go
Program.cs
```

di project biasa.

Bedanya source sisanya bisa di-fetch secara runtime.

Ada dua pattern umum.

**Pattern pertama: single bundle.**

```text
GitHub Raw
└── bundle.lua
```

Bootstrap:

```text
fetch bundle.lua
↓
execute
```

Semua module sudah digabung jadi satu file.

Keuntungannya simpel:

```text
1 HTTP request
1 compile
1 execution
```

Tapi file bisa besar.

Pattern kedua lebih modular:

```text
bootstrap.lua
    ↓
loader.lua
    ↓
manifest
    ↓
core/
ui/
games/
features/
```

Misalnya manifest secara konsep:

```lua
return {
    Core = ".../core.lua",
    UI = ".../ui.lua",
    Universal = ".../universal.lua",

    Games = {
        [123] = ".../games/gameA.lua",
        [456] = ".../games/gameB.lua"
    }
}
```

Loader melihat:

```lua
game.PlaceId
```

kemudian hanya mengambil module yang relevan.

Jadi kalau user berada di Game A:

```text
bootstrap
↓
core
↓
UI
↓
GameA adapter
```

Game B tidak perlu didownload.

Secara architecture malah mirip dynamic import:

```js
const module = await import("./games/gameA.js")
```

Cuma transport-nya HTTP source code.

Yang lebih rapi lagi biasanya punya **module cache**.

Misalnya core meminta module `"UI"` tiga kali:

```text
ModuleLoader.require("UI")
ModuleLoader.require("UI")
ModuleLoader.require("UI")
```

jangan fetch tiga kali.

Loader:

```text
request UI
 ↓
cache exists?
 ├─ yes → return cached module
 └─ no
      ↓
    fetch
      ↓
    execute
      ↓
    cache result
```

Secara konsep:

```lua
local cache = {}

function requireRemote(name)
    if cache[name] then
        return cache[name]
    end

    local source = fetch(resolve(name))
    local module = execute(source)

    cache[name] = module

    return module
end
```

Ini sebenarnya bikin semacam **remote module system** sendiri.

Lalu kenapa GitHub Raw sering dipakai? Karena GitHub menyediakan file mentah:

```text
repo page:
github.com/user/repo/blob/main/main.lua

raw representation:
raw.githubusercontent.com/user/repo/main/main.lua
```

Yang kedua response-nya langsung source text:

```lua
local Foo = {}

function Foo.start()
    ...
end

return Foo
```

jadi cocok untuk loader.

Tapi provider yang lebih matang biasanya tidak mau terlalu bergantung ke branch `main`, karena developer push update bisa langsung merusak semua user.

Mereka biasanya konsepnya memakai versioning:

```text
v1.2.3
v1.2.4
v1.3.0
```

atau commit pinning:

```text
/raw/<commit-hash>/main.lua
```

Sehingga:

```text
loader v1
↓
manifest v1
↓
core v1.4
↓
adapter v2.1
```

bisa tetap reproducible.

Kalau digabung dengan framework tadi, boundary-nya menjadi:

```text
EXECUTOR / RUNTIME
        │
        ▼
   bootstrap.lua
        │
        ▼
 RemoteLoader
        │
        ├── fetch manifest
        ├── version check
        ├── module cache
        └── dependency resolution
                │
                ▼
            Application
                │
      ┌─────────┼─────────┐
      ▼         ▼         ▼
     Core      UI      AdapterRegistry
                           │
                     game.PlaceId
                           │
                           ▼
                       GameAdapter
```

Dan ini menjawab pertanyaan pertama lu juga: **entrypoint project-nya secara logical tetap `bootstrap.lua` atau `main.lua`**.

Executor cuma menjadi host yang menjalankan bootstrap tersebut.

Kalau project-nya proper, jangan bikin seluruh logic ada di entrypoint:

```lua
-- BAD
loadstring(game:HttpGet(...))()

-- terus 10 ribu line logic
```

Lebih sehat:

```text
bootstrap.lua
~20–100 LOC

loader/
module loading

core/
application framework

adapters/
game knowledge

features/
actual functionality

ui/
presentation
```

Jadi kalau diterapkan ke framework yang kita desain tadi:

```text
User
 ↓
Executor
 ↓
bootstrap.lua             ← actual external entrypoint
 ↓
RuntimeBootstrap
 ↓
Application.new()
 ↓
Detector
 ↓
AdapterRegistry
 ↓
WorldModel / Recorder / UI / Automation
```

Yang menarik adalah `loadstring(HttpGet(...))()` itu sebenarnya **bukan framework-nya**. Itu cuma **distribution/bootstrap mechanism**. Framework aslinya baru mulai setelah source sudah berhasil masuk dan dieksekusi.

Kalau lu mau melihatnya seperti software biasa:

```text
GitHub Raw    = package distribution
HttpGet       = downloader
loadstring    = dynamic compiler/loader
bootstrap.lua = process entrypoint
Application   = actual program
```

Itu mental model yang paling tepat.