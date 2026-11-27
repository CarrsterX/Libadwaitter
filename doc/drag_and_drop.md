# Drag & Drop

Cross-platform external drag-and-drop bridges for receiving files, URIs, and
plain text from other desktop, mobile, or browser windows.

## Key APIs

* `AdwDragAndDrop` — Low-level stream (`events`) and outgoing drag starter
  backed by GTK3 on Linux, `View.OnDragListener` on Android, and HTML5 DnD on
  Web.
* `AdwDropTarget` — Declarative drop-zone widget with hover feedback.
* `AdwDragSource` — Declarative outgoing drag-source widget.
* `AdwDropEvent` & `AdwDropEventType` — Lifecycle payloads (`enter`, `update`,
  `leave`, `drop`).
