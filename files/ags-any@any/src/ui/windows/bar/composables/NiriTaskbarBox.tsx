import { Accessor, createBinding, createComputed, For } from "ags";
import options from "../../../../options";
import AstalNiri from "gi://AstalNiri";
import icons from "../../../../lib/icons";
import { checkIconExists } from "../../../../utils";

const niri = AstalNiri.get_default();
const windowsBinding = createBinding(niri, "windows");

const windowsComputed = createComputed([windowsBinding], (windows) => {
   return windows.sort((windowA, windowB) => {
      const workspaceA = windowA.get_workspace();
      const workspaceB = windowB.get_workspace();
      if (workspaceA === null) return -1;
      if (workspaceB === null) return 1;

      if (workspaceA.id !== workspaceB.id) {
         return workspaceA.id - workspaceB.id;
      }

      return windowA.id - windowB.id;
      // Niri does not expose the order of the windows in the same workspace.
   });
});

const focusedWindowBinding = createBinding(
   niri,
   "focusedWindow"
) as Accessor<AstalNiri.Window | null>;

function WindowButton({ window }: { window: AstalNiri.Window }) {
   const isWindowUrgentBinding = createBinding(window, "isUrgent");

   const cssClasses = createComputed(
      [focusedWindowBinding, isWindowUrgentBinding],
      (focusedWindow, isWindowUrgent) => {
         const cssClasses = ["taskbar-client-button"];

         if (isWindowUrgent) {
            cssClasses.push("urgent");
         }

         if (focusedWindow === null) {
            return cssClasses;
         }

         if (focusedWindow.id === window.id) {
            cssClasses.push("active");
         }

         return cssClasses;
      }
   );

   const iconName = () => {
      const windowAppId = window.get_app_id();
      const fallbackIcon = icons.fallback.executable;

      if (!windowAppId)
         return options.bar.niriTaskbar.flat ?
               `${fallbackIcon}-symbolic`
            :  fallbackIcon;

      const icon =
         options.bar.niriTaskbar.flat ? `${windowAppId}-symbolic` : windowAppId;

      return checkIconExists(icon) ? icon : fallbackIcon;
   };

   return (
      <button cssClasses={cssClasses} onClicked={() => window.focus(window.id)}>
         <image iconName={iconName()} />
      </button>
   );
}

export default function () {
   return (
      <box cssClasses={["taskbar-box"]}>
         <For each={windowsComputed}>
            {(window) => <WindowButton window={window} />}
         </For>
      </box>
   );
}
