# lazycat-hermes-studio

LazyCat LPK: Hermes Studio + 持久化 `~/`

## 解决什么问题

容器重启或镜像升级后，安装的工具丢失。持久化整个 `~/` 后，装一次永远在。

## 安装

```bash
lzc-cli lpk install hermes-studio-v0.0.1.lpk
```

## 装工具

进容器后直接：
```bash
uv tool install <package-name>   # → ~/.local/bin/
```

重启不丢，升级不丢。
