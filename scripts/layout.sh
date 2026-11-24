#!/data/data/com.termux/files/usr/bin/bash
# Super+A: cycle the focused container's layout split -> tabbed -> stacking,
# like cycle_layout() in the Hypr keybinds, with a toast that replaces itself.
# (`layout toggle split tabbed stacking` only flips the split orientation
# when the container is split, so the next layout is picked here.)

# Layout of the container holding the focused window
current() {
  i3-msg -t get_tree | jq -r '
    def parent_of_focused:
      if (.nodes + .floating_nodes) | any(.focused) then .layout
      else (.nodes + .floating_nodes)[] | parent_of_focused end;
    [parent_of_focused][0] // empty'
}

case $(current) in
  tabbed)  i3-msg -q layout stacking ;;
  stacked) i3-msg -q layout toggle split ;;
  *)       i3-msg -q layout tabbed ;;
esac

case $(current) in
  splith)  title="Split horizontal" ;;
  splitv)  title="Split vertical" ;;
  tabbed)  title="Tabbed" ;;
  stacked) title="Stacking" ;;
  *)       title="Unknown" ;;
esac

notify-send -a layout -t 1200 -h string:x-canonical-private-synchronous:layout "Layout" "$title"
