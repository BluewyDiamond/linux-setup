import { createBinding, For, onCleanup } from "ags";
import AstalTray from "gi://AstalTray";

const tray = AstalTray.get_default();

function TrayItemMenubutton(trayItem: AstalTray.TrayItem) {
   const actionGroupBinding = createBinding(trayItem, "actionGroup");
   const giconBinding = createBinding(trayItem, "gicon");
   const tooltipMarkupBinding = createBinding(trayItem, "tooltipMarkup");
   const menuModelBinding = createBinding(trayItem, "menuModel");

   return (
      <menubutton
         $={(self) => {
            const unsubscribeActionGroupBinding = actionGroupBinding.subscribe(
               () => {
                  self.insert_action_group("dbusmenu", trayItem.actionGroup);
               }
            );

            onCleanup(() => {
               unsubscribeActionGroupBinding();
            });
         }}
         tooltipMarkup={tooltipMarkupBinding}
         menuModel={menuModelBinding}
      >
         <image gicon={giconBinding} />
      </menubutton>
   );
}

export default function () {
   const trayItemsBinding = createBinding(tray, "items");

   return (
      <box cssClasses={["tray-box"]}>
         <For each={trayItemsBinding}>
            {(trayItem) => TrayItemMenubutton(trayItem)}
         </For>
      </box>
   );
}
