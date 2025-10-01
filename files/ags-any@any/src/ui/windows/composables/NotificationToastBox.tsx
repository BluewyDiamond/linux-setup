import Adw from "gi://Adw";
import AstalNotifd from "gi://AstalNotifd";
import { checkIconExists } from "../../../utils";
import { Gtk } from "ags/gtk4";
import icons from "../../../lib/icons";
import options from "../../../options";

export function NotificationToastBox({
   notification,
   nuke,
}: {
   notification: AstalNotifd.Notification;
   nuke: () => void;
}) {
   return (
      <Adw.Clamp
         maximumSize={options.notificationToasts.notification.maximumSize}
      >
         <box
            cssClasses={["notification-toast-box"]}
            orientation={Gtk.Orientation.VERTICAL}
         >
            <box cssClasses={["notification-header-box"]} hexpand>
               {checkIconExists(notification.appIcon) && (
                  <image
                     cssClasses={["notification-app-image"]}
                     halign={Gtk.Align.START}
                     iconName={notification.app_icon}
                  />
               )}

               <label
                  cssClasses={["notification-summary-label"]}
                  halign={Gtk.Align.CENTER}
                  wrap
                  wrapMode={Gtk.WrapMode.WORD}
                  label={notification.summary}
               />

               <button
                  cssClasses={["notification-close-button"]}
                  hexpand
                  halign={Gtk.Align.END}
                  onClicked={() => nuke()}
               >
                  <image iconName={icons.ui.close} />
               </button>
            </box>

            <box cssClasses={["notification-content-box"]}>
               {notification.get_image() && (
                  <image
                     cssClasses={["notification-body-image"]}
                     file={notification.get_image()}
                  />
               )}

               <label
                  cssClasses={["notification-body-label"]}
                  wrap
                  wrapMode={Gtk.WrapMode.WORD}
                  label={notification.body}
               />
            </box>

            {notification.actions.length > 0 && (
               <box cssClasses={["notification-action-area-box"]} hexpand>
                  {notification.actions.map((action) => (
                     <button
                        cssClasses={["notification-action-button"]}
                        hexpand
                        onClicked={() => notification.invoke(action.id)}
                     >
                        <label label={action.label} />
                     </button>
                  ))}
               </box>
            )}
         </box>
      </Adw.Clamp>
   );
}
