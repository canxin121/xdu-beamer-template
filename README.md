# XDU Beamer Template

一个可独立发布的西安电子科技大学 Beamer 幻灯片模板，适用于毕业答辩、课程汇报、组会分享和学术报告。

## Preview

| Cover | Content |
| --- | --- |
| ![cover preview](docs/preview/cover.png) | ![content preview](docs/preview/content.png) |

## Features

- 16:9 比例，适合投影与线上展示
- 内置封面页、目录页、章节分隔页、普通内容页、致谢页
- 统一的西电红配色、页眉页脚和卡片式内容块
- 自带校园视觉素材，无需依赖外部兄弟目录
- 使用 `XeLaTeX` 编译，适合中英文混排
- 支持将 PDF 打包导出为基于 SVG 的 `.pptx`

## 目录结构

```text
xdu-beamer-template/
├── assets/                 # 背景图、校徽、校训等资源
├── docs/preview/           # README 预览图
├── theme/
│   └── beamerthemeXDU.sty  # 主题样式文件
├── build.sh                # 编译脚本
├── ensure_tectonic.sh      # 缺少 TeX Live 时自动下载 tectonic
├── export_pptx.sh          # 从 PDF 导出 PPTX
├── main.tex                # 最小示例
├── Makefile
├── pptx_base.pptx          # PPTX 导出骨架
└── README.md
```

## 依赖

### 编译 PDF

建议使用带有以下组件的 TeX Live：

- `xelatex`
- `latexmk`
- `beamer`
- `xeCJK`
- `fontspec`
- `tikz`
- `pgfplots`

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y \
  latexmk \
  texlive-xetex \
  texlive-lang-chinese \
  texlive-pictures \
  poppler-utils \
  zip unzip \
  curl tar
```

如果你不想安装完整 TeX Live，也可以只准备 `curl` 和 `tar`，让 `build.sh` 自动下载 `tectonic`。

默认使用的字体：

- 西文字体：`TeX Gyre Termes`、`TeX Gyre Heros`、`Latin Modern Mono`
- 中文字体：`Noto Serif CJK SC`、`Noto Sans CJK SC`、`Noto Sans Mono CJK SC`

如果本机没有安装 Noto CJK 字体，可以在 [main.tex](./main.tex) 中按需替换为本地可用字体。

### 导出 PPTX

`export_pptx.sh` 需要这些命令：

- `pdftocairo`
- `pdftoppm`
- `zip`
- `unzip`
- `sed`
- `sort`

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y poppler-utils zip unzip
```

macOS / Homebrew:

```bash
brew install poppler zip unzip
```

## Quick Start

1. 复制本目录作为新仓库，或直接将其作为模板仓库初始化：

```bash
git init
git add .
git commit -m "init xdu beamer template"
```

2. 编译示例：

```bash
./build.sh main.tex
```

或者：

```bash
make pdf
```

生成结果位于 `build/main.pdf`。

3. 基于示例修改以下元信息：

- `\title{...}`
- `\subtitle{...}`
- `\author{...}`
- `\institute{...}`
- `\advisor{...}`
- `\date{...}`

4. 编写内容页时优先复用主题内置命令：

- `\makexdutitle`：封面页
- `\makexduoutline`：目录页
- `\xdusectionpage{编号}{标题}`：章节分隔页
- `\thankyouframe`：致谢页
- `\cardbox{高度}{标题}{内容}`：固定高度内容卡片
- `\hl{...}`：高亮关键文本
- `\numbadge{...}`：小编号徽章

## 导出 PPTX

有时需要发给只能接收 PowerPoint 的老师或同学，可以把 PDF 打包成 `.pptx`：

```bash
./export_pptx.sh main.tex
```

也可以直接从已有 PDF 导出：

```bash
./export_pptx.sh build/main.pdf dist/main.pptx
```

输出默认位于 `dist/` 目录，例如：

```text
dist/main.pptx
```

说明：

- 导出的每一页会保留 SVG 矢量内容，放大查看时比普通位图截图更清晰。
- 该 PPTX 仍然是“每页一张图”的结构，不是完全原生可编辑的 PowerPoint 文本框。
- 在部分 PowerPoint 版本中，可以对 SVG 执行“转换为形状/取消组合”，得到一定的二次编辑能力。

## 使用建议

- 普通内容页：直接使用 `\begin{frame}{标题}...\end{frame}`。
- 封面：使用 `\makexdutitle`。
- 目录页：使用 `\makexduoutline`。
- 章节分隔页：使用 `\section{...}` 自动触发，或手动写 `\xdusectionpage{01}{标题}`。
- 致谢页：使用 `\thankyouframe`。
- 图文页：建议沿用“左图右文”或“两列卡片”结构，便于答辩展示。

## Repository Layout

```text
xdu-beamer-template/
├── assets/                 # visual assets
├── docs/preview/           # README preview images
├── theme/
│   └── beamerthemeXDU.sty  # reusable beamer theme
├── .github/workflows/      # GitHub Actions CI
├── build.sh                # PDF build helper
├── ensure_tectonic.sh      # tectonic bootstrap helper
├── export_pptx.sh          # PPTX export helper
├── main.tex                # minimal example
├── Makefile
├── NOTICE.md
├── pptx_base.pptx          # PPTX skeleton package
└── README.md
```

## Design Notes

这个模板从现有答辩工程中抽取了可复用的视觉与版式能力，并做了以下整理：

- 去除了具体课题内容
- 去除了对外部目录图表和资源的依赖
- 将主题逻辑封装到独立 `.sty` 文件中
- 提供一个最小可修改示例，而不是绑定某一份具体答辩稿

## License

模板代码采用 [MIT License](LICENSE)。

校徽、校名与校园图片等视觉资源的使用边界见 [NOTICE.md](NOTICE.md)。
