# win_test

仅包含 Windows 平台的 Flutter 空白项目，通过官方命令生成：

```sh
flutter create --empty --platforms=windows --project-name win_test .
```

保留默认的 `Hello World!` 页面，没有额外功能或第三方运行时依赖。Flutter 版本为 **3.47.9 stable**，依赖版本记录在 `pubspec.lock`。

## Windows ARM64 支持情况

核查日期：2026-11-03。

- [Flutter 官方支持矩阵](https://docs.flutter.dev/reference/supported-platforms)列出 Windows 10、11 的 x64 和 ARM64 支持。
- [Flutter Windows 构建命令源码](https://github.com/flutter/flutter/blob/3.47.9/packages/flutter_tools/lib/src/commands/build_windows.dart)根据运行 Flutter 工具的 Dart 主机架构选择目标；该版本没有 `--target-platform` 参数。Windows 构建必须在 Windows 主机上执行。
- [官方 SDK 初始化脚本](https://github.com/flutter/flutter/blob/3.47.9/bin/internal/update_dart_sdk.ps1)会在原生 ARM64 环境下载 ARM64 Dart SDK。仅有 ARM64 runner 不够：如果运行的是 x64 Dart，Flutter 仍会选择 x64 目标。
- 因此 CI 在两个原生 runner 上分别从固定版本的 Flutter 源码初始化 SDK，并检查 Dart、最终 EXE 和 Flutter DLL 的 PE 架构；若 ARM64 SDK 回退成 x64，任务会失败。

## GitHub Actions

工作流：[`.github/workflows/windows.yml`](.github/workflows/windows.yml)。

每次 push、pull request 或手动触发 `Build Windows`，都会执行依赖解析、格式检查、静态分析和 Release 构建：

| 目标 | GitHub runner | 下载产物 |
| --- | --- | --- |
| x86-64 / x64 | `windows-2022` | `win_test-windows-x64` |
| ARM64 | `windows-11-arm` | `win_test-windows-arm64` |

runner 标签依据 [GitHub 官方文档](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)。无需配置自定义 Secret。

将项目推送到 GitHub 仓库后，在 **Actions → Build Windows → 对应运行 → Artifacts** 下载产物，保留 14 天。上传的是整个 Release 目录，包含 EXE、Flutter DLL 和 `data`，下载后应完整解压，不能仅复制 EXE。

目标电脑需要安装对应架构的 Visual C++ 运行库；此工作流不生成安装包、不签名，也不发布 GitHub Release。分发要求参见 [Flutter 官方 Windows 打包说明](https://docs.flutter.dev/platform-integration/windows/building#building-your-own-zip-file-for-windows)。

## 本地运行与编译

在对应架构的 Windows 环境安装 Flutter 3.47.9、Visual Studio 2022 的 **Desktop development with C++** 工作负载及 Windows SDK；ARM64 环境还需 ARM64 C++ 工具，并确保 Dart SDK 本身为 ARM64。参见 [官方环境配置说明](https://docs.flutter.dev/platform-integration/windows/setup)。

```powershell
flutter doctor -v
flutter pub get --enforce-lockfile
flutter run -d windows
flutter build windows --release
```

输出路径为 `build/windows/x64/runner/Release/` 或 `build/windows/arm64/runner/Release/`。

项目创建于 macOS；Windows 原生编译结果需要以 GitHub Actions 实际运行结果为准。
