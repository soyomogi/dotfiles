const { Plugin, PluginSettingTab, Setting, Notice } = require("obsidian");
const { execFile } = require("node:child_process");
const { access, readFile } = require("node:fs/promises");
const { constants } = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const DEFAULTS = { executable: "", port: 19420, customTheme: true, themePath: "theme.css" };

module.exports = class SkillshareUIPlugin extends Plugin {
  async onload() {
    this.unloaded = false;
    this.dashboardTabs = new Map();
    this.settings = { ...DEFAULTS, ...(await this.loadData()) };
    this.theme = new SkillshareTheme({
      getPath: () => this.settings.customTheme ? this.resolveThemePath(this.settings.themePath) : "",
      isDashboard: url => this.isDashboardURL(url),
      onError: error => console.warn("Skillshare UI theme:", error),
    });
    this.registerEvent(this.app.workspace.on("layout-change", () => this.checkDashboardTabs()));
    // Web viewer can mount its webview after the layout event.
    const observer = new MutationObserver(records => {
      if (records.some(record => [...record.addedNodes, ...record.removedNodes].some(node =>
        node.nodeType === 1 && (node.matches("webview") || node.querySelector("webview"))))) {
        this.checkDashboardTabs();
      }
    });
    observer.observe(this.app.workspace.containerEl, { childList: true, subtree: true });
    this.register(() => observer.disconnect());
    this.app.workspace.onLayoutReady(() => {
      if (!this.unloaded) this.checkDashboardTabs();
    });
    this.addCommand({
      id: "start-server",
      name: "Start server",
      callback: () => this.openDashboard(),
    });
    this.addCommand({
      id: "stop-server",
      name: "Stop server",
      callback: () => this.stopServerCommand(),
    });
    this.addCommand({
      id: "reload-theme",
      name: "Reload theme",
      callback: async () => {
        this.checkDashboardTabs();
        await this.theme.reload();
      },
    });
    this.addRibbonIcon("panels-top-left", "Open Skillshare UI", () => this.openDashboard());
    this.addSettingTab(new SkillshareSettings(this.app, this));
  }

  onunload() {
    this.unloaded = true;
    this.theme.dispose();
  }

  isDashboardURL(value) {
    try {
      const url = new URL(value);
      return url.protocol === "http:" && ["127.0.0.1", "localhost"].includes(url.hostname)
        && (Number(url.port || 80) === Number(this.settings.port)
          || this.dashboardTabs.has(Number(url.port || 80)));
    } catch (_) { return false; }
  }

  checkDashboardTabs() {
    if (this.unloaded) return;
    const leaves = this.app.workspace.getLeavesOfType("webviewer");
    const openLeaves = new Set(leaves);
    for (const leaf of leaves) {
      try {
        const url = new URL(leaf.getViewState().state?.url);
        if (url.protocol === "http:" && url.hostname === "127.0.0.1") {
          const port = Number(url.port || 80);
          if (port === Number(this.settings.port) || this.dashboardTabs.has(port)) {
            if (!this.dashboardTabs.has(port)) this.dashboardTabs.set(port, new Set());
            this.dashboardTabs.get(port).add(leaf);
          }
        }
      } catch (_) { /* Ignore blank Web viewer tabs. */ }
    }
    for (const [port, tabs] of this.dashboardTabs) {
      for (const leaf of tabs) {
        if (!openLeaves.has(leaf)) tabs.delete(leaf);
      }
      if (tabs.size) continue;
      this.dashboardTabs.delete(port);
      this.stopServerCommand(port);
    }
    this.theme.sync(leaves.filter(leaf => this.isDashboardURL(leaf.getViewState().state?.url))
      .map(leaf => leaf.view.webview || leaf.view.containerEl.querySelector("webview")).filter(Boolean));
  }

  resolveThemePath(themePath) {
    const value = (themePath || "").trim();
    if (!value) return "";
    if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
    if (path.isAbsolute(value)) return value;
    // Relative paths resolve against the plugin folder, so the default
    // "theme.css" names the file installed next to main.js.
    const basePath = this.app.vault.adapter.getBasePath?.() || "";
    const pluginDir = this.manifest?.dir || "";
    return basePath && pluginDir ? path.join(basePath, pluginDir, value) : value;
  }

  async resolveExecutable() {
    if (this.settings.executable.trim()) return this.settings.executable.trim();
    const directories = [
      ...(process.env.PATH || "").split(path.delimiter),
      "/opt/homebrew/bin", "/usr/local/bin", path.join(os.homedir(), ".local", "bin"),
    ];
    for (const directory of directories.filter(Boolean)) {
      const candidate = path.join(directory, process.platform === "win32" ? "skillshare.exe" : "skillshare");
      try {
        await access(candidate, constants.X_OK);
        return candidate;
      } catch (_) { /* Try the next installation directory. */ }
    }
    throw new Error("skillshare が見つかりません。設定で実行ファイルの絶対パスを指定してください。");
  }

  getPort() {
    const port = Number(this.settings.port);
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      throw new Error("ポートは 1〜65535 の整数で指定してください。");
    }
    return port;
  }

  startServer(port) {
    return this.runServer("start", port);
  }

  runServer(action, port) {
    // Serialize start/stop so a stop requested during startup runs afterwards.
    const operation = (this.serverOperation || Promise.resolve())
      .then(() => this.executeServer(action, port));
    this.serverOperation = operation.catch(() => {});
    return operation;
  }

  async stopServerCommand(port) {
    const progress = new Notice("Skillshare UI を停止しています…", 0);
    try {
      await this.runServer("stop", port ?? this.getPort());
      new Notice("Skillshare UI サーバーを停止しました。");
    } catch (error) {
      console.error("Skillshare UI:", error);
      new Notice(`Skillshare UI: ${error.message}`, 12000);
    } finally {
      progress.hide();
    }
  }

  async executeServer(action, port) {
    const executable = await this.resolveExecutable();
    // GUI apps on macOS may omit Homebrew and other CLI locations from PATH.
    const env = {
      ...process.env,
      PATH: [path.dirname(executable), process.env.PATH, "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"].filter(Boolean).join(path.delimiter),
    };
    const args = ["ui", action, "--global", "--host", "127.0.0.1", "--port", String(port)];
    if (action === "start") args.push("--no-open");
    await new Promise((resolve, reject) => {
      execFile(executable, args,
        { cwd: os.homedir(), env, timeout: 60000, maxBuffer: 1024 * 1024, windowsHide: true },
        (error, stdout, stderr) => {
          if (error) {
            reject(new Error((stderr || stdout || error.message).trim()));
          } else {
            resolve();
          }
        });
    });
  }

  async openDashboard() {
    // Multiple clicks share the complete start/open operation.
    if (this.opening) return this.opening;
    this.opening = this.doOpenDashboard().catch(error => {
      console.error("Skillshare UI:", error);
      new Notice(`Skillshare UI: ${error.message}`, 12000);
    }).finally(() => { this.opening = null; });
    return this.opening;
  }

  async doOpenDashboard() {
    if (!this.app.internalPlugins.getPluginById("webviewer")?.enabled) {
      throw new Error("設定 → コアプラグインで Web viewer を有効にしてください。");
    }
    const port = this.getPort();
    const progress = new Notice("Skillshare UI を起動しています…", 0);
    try {
      await this.startServer(port);
      if (this.unloaded) return;
      const url = `http://127.0.0.1:${port}`;
      const existing = this.app.workspace.getLeavesOfType("webviewer").find(leaf => {
        try { return new URL(leaf.getViewState().state?.url).origin === url; }
        catch (_) { return false; }
      });
      const leaf = existing || this.app.workspace.getLeaf("tab");
      if (!existing) {
        await leaf.setViewState({ type: "webviewer", active: true, state: { url } });
      }
      await this.app.workspace.revealLeaf(leaf);
      this.app.workspace.setActiveLeaf(leaf, { focus: true });
      if (!this.dashboardTabs.has(port)) this.dashboardTabs.set(port, new Set());
      this.dashboardTabs.get(port).add(leaf);
      this.checkDashboardTabs();
      await this.theme.reload();
    } finally {
      progress.hide();
    }
  }
};

class SkillshareSettings extends PluginSettingTab {
  constructor(app, plugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display() {
    this.containerEl.empty();
    new Setting(this.containerEl)
      .setName("Custom theme")
      .setDesc("共有 CSS を Skillshare の Web viewer に適用します。通常のブラウザでは Chrome 拡張から同じ CSS を利用できます。")
      .addToggle(toggle => toggle.setValue(this.plugin.settings.customTheme)
        .onChange(async value => {
          this.plugin.settings.customTheme = value;
          await this.plugin.saveData(this.plugin.settings);
          await this.plugin.theme.reload();
        }));
    new Setting(this.containerEl)
      .setName("Theme CSS path")
      .setDesc("共有 CSS のパス。相対パスはプラグインのフォルダ基準です。~/ も使用できます。変更後は Reload theme でも再読み込みできます。")
      .addText(text => text.setValue(this.plugin.settings.themePath)
        .onChange(async value => {
          this.plugin.settings.themePath = value.trim();
          await this.plugin.saveData(this.plugin.settings);
          await this.plugin.theme.reload();
        }));
    new Setting(this.containerEl)
      .setName("Skillshare executable")
      .setDesc("空欄なら自動検出します。指定する場合は実行ファイルの絶対パスを入力してください。")
      .addText(text => text.setPlaceholder("/opt/homebrew/bin/skillshare")
        .setValue(this.plugin.settings.executable)
        .onChange(async value => {
          this.plugin.settings.executable = value.trim();
          await this.plugin.saveData(this.plugin.settings);
        }));
    new Setting(this.containerEl)
      .setName("Port")
      .setDesc("Skillshare UI のポート。標準は 19420。次回開くときに適用されます。")
      .addText(text => text.setValue(String(this.plugin.settings.port))
        .onChange(async value => {
          const port = Number(value);
          if (!Number.isInteger(port) || port < 1 || port > 65535) return;
          this.plugin.settings.port = port;
          await this.plugin.saveData(this.plugin.settings);
        }));
  }
}

// Apply the shared stylesheet through Electron, without changing cached UI assets.
class SkillshareTheme {
  constructor({ getPath, isDashboard, onError }) {
    this.getPath = getPath;
    this.isDashboard = isDashboard;
    this.onError = onError;
    this.views = new Map();
  }

  sync(webviews) {
    const active = new Set(webviews);
    for (const [view, state] of this.views) {
      if (!active.has(view)) this.release(view, state);
    }
    for (const view of active) {
      if (this.views.has(view)) continue;
      const state = { key: null, css: null, pending: Promise.resolve(), disposed: false, generation: 0 };
      state.ready = () => {
        // A new document no longer contains the previous insertion.
        state.generation++;
        state.key = null;
        state.css = null;
        this.schedule(view, state);
      };
      view.addEventListener("dom-ready", state.ready);
      // The URL is not settled when a tab first opens: the initial apply can
      // run against a blank document, and that document's dom-ready may have
      // already fired before this listener was attached. Re-check when the
      // navigation commits and when the load finishes, when the URL is final.
      view.addEventListener("did-navigate", state.ready);
      view.addEventListener("did-finish-load", state.ready);
      this.views.set(view, state);
      this.schedule(view, state);
    }
  }

  reload() {
    return Promise.all([...this.views].map(([view, state]) => this.schedule(view, state)));
  }

  schedule(view, state) {
    state.pending = state.pending.then(() => this.apply(view, state)).catch(this.onError);
    return state.pending;
  }

  async apply(view, state) {
    if (state.disposed) return;
    const generation = state.generation;
    let url;
    try { url = view.getURL(); } catch (_) { return; } // Not mounted yet.
    const filename = this.getPath().trim();
    let css = "";
    if (filename && this.isDashboard(url)) {
      const resolved = filename.startsWith("~/") ? path.join(os.homedir(), filename.slice(2)) : filename;
      try { css = await readFile(resolved, "utf8"); }
      catch (error) { if (error.code !== "ENOENT") throw error; }
    }
    if (state.disposed || state.generation !== generation || view.getURL() !== url) return;
    if (css === state.css) return;
    const previous = state.key;
    const key = css ? await view.insertCSS(css) : null;
    if (state.disposed || state.generation !== generation || view.getURL() !== url) {
      if (key) await view.removeInsertedCSS(key).catch(() => {});
      return;
    }
    state.key = key;
    state.css = css;
    if (previous) await view.removeInsertedCSS(previous).catch(() => {});
  }

  release(view, state) {
    state.disposed = true;
    view.removeEventListener("dom-ready", state.ready);
    view.removeEventListener("did-navigate", state.ready);
    view.removeEventListener("did-finish-load", state.ready);
    try {
      if (state.key) Promise.resolve(view.removeInsertedCSS(state.key)).catch(() => {});
    } catch (_) { /* A closed webview may already have been destroyed. */ }
    this.views.delete(view);
  }

  dispose() {
    for (const [view, state] of this.views) this.release(view, state);
  }
};

