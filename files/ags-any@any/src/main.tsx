import app from "ags/gtk4/app";
// @ts-expect-error stop_complaining
import style from "./scss/main.scss";
import BarWindow from "./ui/windows/bar/BarWindow.tsx";
import NotificationToastsWindow from "./ui/windows/notificationToasts/NotificationToastsWindow.tsx";
import ControlCenterWindow from "./ui/windows/controlCenter/ControlCenterWindow.tsx";
import {
   createExternal,
   For,
   This,
} from "ags";
import { timeout } from "ags/time.ts";
import Gdk from "gi://Gdk";

app.start({
   css: style,

   main() {
      five();
   },
});

function five() {
   const gdkDisplay = Gdk.Display.get_default()!;
   const monitors = gdkDisplay.get_monitors();

   const monitorsExternal = createExternal<Gdk.Monitor[]>([], (set) => {
      const onMonitorsChanged = () => {
         const monitorsLength = monitors.get_n_items();
         const newMonitors: Gdk.Monitor[] = [];

         for (let i = 0; i < monitorsLength; i++) {
            const monitor = monitors.get_item(i);
            if (monitor === null) continue;
            if (!(monitor instanceof Gdk.Monitor)) continue;

            newMonitors.push(monitor);
         }

         // setTimeout from ags doesn't work as expected and leads to a crash
         // timeout from astal works fine
         // it is needed because as user mentioned the monitor starts as null and is later changed
         timeout(2000, () => {
            set(newMonitors);
         });
      };

      const itemsChangedSignalID = monitors.connect("items-changed", () => {
         onMonitorsChanged();
      });

      onMonitorsChanged();

      return () => {
         monitors.disconnect(itemsChangedSignalID);
      };
   });

   return (
      <For each={monitorsExternal}>
         {(monitor) => (
            <This this={app}>
               <BarWindow gdkmonitor={monitor} />
               <ControlCenterWindow gdkmonitor={monitor} />
               <NotificationToastsWindow gdkmonitor={monitor} />
            </This>
         )}
      </For>
   );
}
