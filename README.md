# Gallery — 个人摄影作品站

基于 [Hugo](https://gohugo.io/) + [hugo-theme-gallery](https://github.com/nicokaiser/hugo-theme-gallery) 的个人摄影作品展示站,部署于 GitHub Pages。

🌐 **在线站点:https://hyc.ac/gallery/**  ·

照片按**项目 / 相册**两级组织:首页是 Me、旅行、猫狗等分组的卡片墙;进入「旅行」后按行程(云南行 / 江苏)再次细分,点进相册即照片墙,支持灯箱查看与多尺寸响应式缩略图。

## 架构:内容与主体分离

参照 **内容仓库(私有)与站点仓库(公开)分离** 的模式,照片不在本仓库:

```
Hi-Yincan/gallery(本仓库 · 公开)          Hi-Yincan/gallery-content(私有)
│  config.toml                             │  Me/              ← 相册(照片墙)
│  themes/hugo-theme-gallery/ ←submodule  │  旅行/云南行 江苏  ← 按行程项目
│  content/ ────submodule───────────────→ │  猫狗/            ← 相册(照片墙)
│  .github/workflows/deploy.yml            │  README.md(操作指南)
```

- **内容是私有 submodule**:照片原图与项目结构留在私有仓库,公开仓库只有站点代码
- **发布链路**:内容仓库 `push` → `repository_dispatch` 触发本仓库 Actions → 拉取最新内容 → `hugo --minify` → 推送 `gh-pages` → GitHub Pages 发布(域名 `hyc.ac` 绑定在组织主站,本仓库作为项目仓库自动获得 `/gallery/` 子路径)

## 本地开发

```bash
git clone --recurse-submodules https://github.com/Hi-Yincan/gallery.git
git submodule update --init --remote content   # 内容子模块为私有仓库,需具备访问权限的 Git 凭证
hugo server                                     # http://localhost:1313/gallery/

# 本地最新构建
hugo --minify && python3 -m http.server -d public
```

> 无内容仓库权限时,`content/` 子模块无法初始化,构建站点缺内容但代码结构完整。

## 部署

| 触发方式 | 说明 |
|---|---|
| 内容仓库 push | 自动(dispatch 触发) |
| 本仓库 push / 手动 | `gh workflow run deploy -R Hi-Yincan/gallery` |

工作流需要一名为 `PAT` 的 secret(读取私有内容子模块),内容仓库需要 `DISPATCH_TOKEN`(触发 dispatch)。配置方式见 `setup-deploy.sh`。

## 感谢

- [hugo-theme-gallery](https://github.com/nicokaiser/hugo-theme-gallery) · 优雅极简的 Hugo 相册主题——PhotoSwipe 灯箱、EXIF 图注、justified 布局、图片管线全部用它完成。© [nicokaiser](https://github.com/nicokaiser),MIT License。
- 内容-主体分离的仓库架构参考本人博客 [Hi-Yincan/blog](https://github.com/Hi-Yincan/blog)。

## License

- 站点代码(MIT License)
- 图片与内容:版权所有 © Yincan Huang,保留一切权利
