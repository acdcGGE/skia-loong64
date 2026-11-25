# loong64-aseprite — 面向 Aseprite 的自包含 Skia 预编译包

本分支基于 `loong64` 分支（commit `4480fc46`，tag `skia-m124-loong64`），
只增加本文档，用于说明该仓库 release 中 `skia-m124-loong64-aseprite`
所附带的补全版预编译包。源码/构建脚本本身与 `loong64` 分支一致。

## 为什么有这个包

上游 release `skia-m124-loong64` 的 `skia-loong64.tar.zst` 只含静态库和部分
头文件，直接拿它编译 Aseprite 会遇到三类问题：

1. 缺 `modules/skcms`、`src/core` 等 Skia 内部头文件；
2. 缺 `icudtl.dat`，且 `libjpeg-turbo` / `libpng` / `libwebp` 的 include
   路径在原构建机上是指向本机的绝对符号链接；
3. Skia 用 ICU 78 符号编译，而常见发行版（如 Deepin 25）自带 ICU 74，
   链接时会出现 `u_xxx_78` 未定义符号。

`skia-m124-loong64-aseprite` release 下的两个 asset 解决以上问题：

| asset | 内容 |
| --- | --- |
| `skia-loong64-aseprite.tar.zst` | 原始库 + 补齐的 `modules/` `src/` 头文件 + `icudtl.dat`；三个 externals 改为自包含真实头文件；`lib/libjpeg.a` |
| `icu78-loong64-static.tar.zst` | 原生编译的 ICU 78.3 静态库（`libicuuc.a` / `libicui18n.a` / `libicudata.a`） |

压缩包内无任何绝对路径符号链接，可解压到任意目录使用。

## 编译 Aseprite

需要 Aseprite 的 LoongArch64 适配分支（如 `acdcGGE/aseprite-loong64`
的 `loong64` 分支，其中 `laf/cmake/FindSkia.cmake` 支持 `SKIA_ICU_ROOT`）：

```sh
tar --zstd -xf skia-loong64-aseprite.tar.zst
tar --zstd -xf icu78-loong64-static.tar.zst

cd aseprite-loong64
# 打 loong64 补丁（laf-loongarch64.patch）后：
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR=/path/to/skia-loong64 \
  -DSKIA_LIBRARY_DIR=/path/to/skia-loong64/lib \
  -DLIBJPEG_TURBO_LIBRARY=/path/to/skia-loong64/lib/libjpeg.a \
  -DSKIA_ICU_ROOT=/path/to/icu78/lib
ninja -C build aseprite
```

## 验证

发布前用上述配置在 Deepin 25 / LoongArch64（gcc 12.3）上从零编译通过，
`aseprite --version` 为 `Aseprite 1.3.18.6`，`ldd` 无缺失动态库。

## License

Skia 本体遵循原仓库 BSD-3-Clause。附带的 libjpeg-turbo / libpng / libwebp
头文件与 ICU 78 静态库分别遵循其各自上游许可证；请以各上游项目为准。
