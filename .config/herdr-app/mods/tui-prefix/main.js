import { View, div } from "gpui-kit";
import { checking, closeOverlay, focused, hc, nextCommand, panes, props, run, theme } from "herdr";

const bindings = new Map([
  ["c", ["New tab", "tab.new"]],
  ["n", ["Next tab", "tab.next"]],
  ["p", ["Previous tab", "tab.prev"]],
  ["T", ["Rename tab", "tab.rename"]],
  ["X", ["Close tab", "tab.close"]],
  ["v", ["Split right", "pane.split", { direction: "right" }]],
  ["-", ["Split down", "pane.split", { direction: "down" }]],
  ["x", ["Close pane", "pane.close"]],
  ["z", ["Zoom pane", "pane.zoom"]],
  ["P", ["Rename pane", "pane.rename"]],
  ["N", ["New space", "space.new"]],
  [",", ["Previous space", "space.prev"]],
  [".", ["Next space", "space.next"]],
  ["W", ["Rename space", "space.rename"]],
  ["D", ["Close space", "space.close"]],
  ["g", ["Go to tab, space or agent", "mod.open", { name: "picker" }]],
  ["w", ["Open space picker", "mod.open", { name: "picker" }]],
  ["f", ["Toggle Files", "mod.open", { name: "files-shortcut" }]],
  ["b", ["Toggle sidebar", "layout.toggle", { id: "sidebar" }]],
  ["s", ["Settings", "app.settings"]],
]);

for (const [key, direction] of [["h", "left"], ["j", "down"], ["k", "up"], ["l", "right"]]) {
  bindings.set(key, [`Focus ${direction}`, "pane.go", { direction }]);
  bindings.set(key.toUpperCase(), [`Swap ${direction}`, "pane.swap", { direction }]);
}

for (let index = 1; index <= 9; index++) {
  bindings.set(String(index), [`Tab ${index}`, "tab.select", { index }]);
}

function cyclePane(step) {
  const current = focused();
  if (!current?.pane) return;
  const inTab = panes().filter((pane) => pane.tab === current.tab);
  const index = inTab.findIndex((pane) => pane.pane === current.pane);
  if (index < 0 || inTab.length < 2) return;
  const next = inTab[(index + step + inTab.length) % inTab.length];
  run("pane.focus", { pane: next.pane });
}

export default class TuiPrefix extends View {
  init(_props, cx) {
    this.focus = cx.focus_handle();
    this.focus.focus();
    this.showBindings = false;
    if (checking()) return;
    cx.spawn(async () => {
      await nextCommand();
      this.sendPrefix();
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  sendPrefix() {
    const terminal = focused()?.terminal;
    if (terminal) hc(["keys", terminal, "ctrl+b"]);
    this.dismiss();
  }

  onKey(event, cx) {
    cx.stop_propagation();
    const { control, alt, platform, shift } = event.modifiers;
    if (control && !alt && !platform && !shift && event.key === "b") {
      this.sendPrefix();
      return;
    }
    const key = event.key_char ?? (shift ? event.key.toUpperCase() : event.key);
    if (!control && !alt && !platform && key === "?") {
      this.showBindings = !this.showBindings;
      cx.notify();
      return;
    }
    if (!control && !alt && !platform && event.key === "tab") {
      this.dismiss();
      cyclePane(shift ? -1 : 1);
      return;
    }
    const binding = !control && !alt && !platform && bindings.get(key);
    this.dismiss();
    if (binding) {
      const [, command, args] = binding;
      run(command, args);
    }
  }

  render() {
    const colors = theme();
    const rows = this.showBindings ? [...bindings] : [...bindings].slice(0, 10);
    return div()
      .id("tui-prefix")
      .track_focus(this.focus)
      .on_key_down((event, cx) => this.onKey(event, cx))
      .p(14).bg(colors.popover).text_color(colors.foreground).text_size(12)
      .child(div().font_semibold().child("Ctrl+B"))
      .child(div().text_color(colors.muted).child("Esc cancel · Ctrl+B send · ? bindings"))
      .child(div().text_color(colors.muted).child("Tab / Shift+Tab cycle panes"))
      .child(div().id("tui-prefix-bindings").h(295).overflow_y_scrollbar().children(
        rows.map(([key, [label]]) => div().flex().gap(12)
          .child(div().w(24).text_color(colors.accent).child(key))
          .child(div().child(label))),
      ));
  }
}
