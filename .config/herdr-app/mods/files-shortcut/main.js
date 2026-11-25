import { View, div } from "gpui-kit";
import { closeOverlay, layout, props, run } from "herdr";

function findBlock(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const match = findBlock(child, id);
    if (match) return match;
  }
}

export default class FilesShortcut extends View {
  init(_props, cx) {
    const overlay = props()?.overlay;
    if (!overlay) return;

    cx.spawn(async () => {
      closeOverlay(overlay);
      const panel = findBlock(layout(), "panel");
      const stack = findBlock(panel, "panel-body");
      if (!stack?.children?.some((child) => child.id === "files")) return;

      if (!panel.hidden && stack.active === "files") {
        run("layout.hide", { id: "panel" });
        return;
      }
      run("layout.select", { stack: "panel-body", child: "files" });
      run("layout.show", { id: "panel" });
    });
  }

  render() {
    return div();
  }
}
