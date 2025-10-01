import app from "ags/gtk4/app";
import { Astal, Gdk } from "ags/gtk4";
import DateTimeMenuButton from "./composables/DateTimeMenubutton";
import IndicatorsBox from "./composables/IndicatorsBox";
import TrayBox from "./composables/TrayBox";
import { Accessor, onCleanup } from "ags";
import NiriStaticWorkspacesBox from "./composables/NiriStaticWorkspacesBox";
import NiriTaskbarBox from "./composables/NiriTaskbarBox";
import options from "../../../options";

export default function BarWindow({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
   const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

   return (
      <window
         $={(self) => onCleanup(() => self.destroy())}
         gdkmonitor={gdkmonitor}
         name={options.bar.name}
         namespace={options.bar.name}
         cssClasses={["bar-window"]}
         anchor={TOP | LEFT | RIGHT}
         exclusivity={Astal.Exclusivity.EXCLUSIVE}
         application={app}
         visible
      >
         <centerbox>
            <box $type="start">
               <NiriStaticWorkspacesBox />
               <NiriTaskbarBox />
            </box>

            <centerbox $type="center">
               <box $type="start"></box>

               <box $type="center">
                  <DateTimeMenuButton $type="center" />
               </box>

               <box $type="end"></box>
            </centerbox>

            <box $type="end">
               <TrayBox />
               <IndicatorsBox />
            </box>
         </centerbox>
      </window>
   );
}
