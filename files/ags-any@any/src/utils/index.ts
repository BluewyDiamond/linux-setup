import { Gdk, Gtk } from "ags/gtk4";

export function checkIconExists(icon: string): boolean {
   if (icon === "") {
      return false;
   }

   const display = Gdk.Display.get_default();

   if (display === null) {
      printerr("display === null");
      return false;
   }

   const iconTheme = Gtk.IconTheme.get_for_display(display);
   return iconTheme.has_icon(icon);
}
