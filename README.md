# done-alert — Claude Code 任务完成提示（语音 + 全屏弹图）

一个 [Claude Code](https://claude.com/claude-code) skill：每次任务结束（Stop）时，**播放一段语音 + 在所有屏幕全屏弹出一张大图**。提示图显示期间，按任何键 / 点屏幕任何位置都只用于关闭这张图，**不会误操作到电脑**；关闭后键盘鼠标立即恢复正常。

适合「切到别的窗口干活、容易错过 Claude 跑完」的场景。

> ⚠️ **仅限 macOS**，依赖系统自带的 `afplay` 和 `swift`。

## 效果

- 🔊 任务结束播放你自己的语音（`done.mp3`）
- 🖼️ 所有显示器同时弹出你自己的图片（透明底 PNG 最佳），居中、无边框、占屏高 70%
- ⌨️🖱️ 按任意键 / 点击任意位置关闭，期间不会误触电脑

## 安装

1. 把本仓库克隆（或下载）到 Claude Code 的 skills 目录：
   ```bash
   git clone https://github.com/<你的用户名>/claude-done-alert ~/.claude/skills/done-alert
   ```
2. 重启 Claude Code（让它扫描到新 skill）。
3. 在对话里输入 `/done-alert`，或直接说「装提示音」。

skill 会引导你：提供声音 → 提供图片 → 自动建目录、编译弹图程序、把 Stop hook 合并进 `~/.claude/settings.json`、校验并自测。

## 你需要自备

- **声音**：mp3 / m4a / wav / aiff，任意时长（建议 1~2 秒）。录制可用「语音备忘录」或剪映（文本朗读后单独导出音频）。
- **图片**：建议**透明底 PNG**（用 macOS 照片 App 的「抠图」或在线工具去背景）。

## 生效

Stop hook 改动后，需要在 Claude Code 里打开一次 `/hooks` 菜单或重启扩展，才会在真实任务结束时生效。

## 自定义

- 换声音/图片：直接覆盖 `~/.claude/sounds/done.mp3` 或 `~/.claude/sounds/alert.png`，配置不用动。
- 图片大小：改 Stop hook 命令里的 `0.7`（占屏幕高度比例，`0.4`~`0.9`）。

## 手动安装（不走 skill）

不想用 skill 的话，`SKILL.md` 里「执行步骤」一节就是完整手动流程，照做即可。

## License

MIT
