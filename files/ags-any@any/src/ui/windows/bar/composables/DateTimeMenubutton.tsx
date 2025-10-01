import { createState } from "ags";
import { Gtk } from "ags/gtk4";
import { interval } from "ags/time";
import GLib from "gi://GLib";

export default function () {
   const [labelState, setLabelState] = createState("");

   interval(1000, () => {
      let now = GLib.DateTime.new_now_local();
      let label = now.format("%a %d %b - %H:%M");

      if (label === null) {
         return;
      }

      setLabelState(label);
   });

   return (
      <menubutton
         $type="end"
         cssClasses={["date-time-menubutton"]}
         hexpand
         halign={Gtk.Align.CENTER}
      >
         <label cssClasses={["label"]} label={labelState} />

         <popover>
            <Gtk.Calendar />
         </popover>
      </menubutton>
   );
}
