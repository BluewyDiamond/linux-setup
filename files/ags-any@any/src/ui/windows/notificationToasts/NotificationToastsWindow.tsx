import { Accessor, createComputed, createState, For, onCleanup } from "ags";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import app from "ags/gtk4/app";
import { timeout } from "ags/time";
import AstalNotifd from "gi://AstalNotifd";
import options from "../../../options";
import icons from "../../../lib/icons";
import { checkIconExists } from "../../../utils";
import Adw from "gi://Adw";
import { NotificationToastBox } from "../composables/NotificationToastBox";

const notifd = AstalNotifd.get_default();

export default function ({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
   const [notificationsState, setNotificationsState] = createState<
      AstalNotifd.Notification[]
   >([]);

   const notifiedSignalId = notifd.connect("notified", (_, id) => {
      const notification = notifd.get_notification(id);

      setNotificationsState((previousNotifications) => {
         return [notification, ...previousNotifications];
      });

      timeout(options.notificationToasts.timeout, () =>
         setNotificationsState((previousNotifications) => {
            return previousNotifications.filter(
               (previousNotification) => previousNotification.id !== id
            );
         })
      );
   });

   const resolvedSignalId = notifd.connect("resolved", (_, id) => {
      setNotificationsState((previousNotifications) => {
         return previousNotifications.filter(
            (previousNotification) => previousNotification.id !== id
         );
      });
   });

   onCleanup(() => {
      notifd.disconnect(notifiedSignalId);
      notifd.disconnect(resolvedSignalId);
   });

   const visible = createComputed([notificationsState], (notifications) =>
      notifications.length > 0 ? true : false
   );

   return (
      <window
         $={(self) => onCleanup(() => self.destroy())}
         gdkmonitor={gdkmonitor}
         name={options.notificationToasts.name}
         namespace={options.notificationToasts.name}
         cssClasses={["notification-toasts-window"]}
         anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
         exclusivity={Astal.Exclusivity.EXCLUSIVE}
         application={app}
         visible={visible}
      >
         <box
            cssClasses={["notification-toasts-box"]}
            orientation={Gtk.Orientation.VERTICAL}
         >
            <For each={notificationsState}>
               {(notification) => (
                  <NotificationToastBox
                     notification={notification}
                     nuke={() =>
                        setNotificationsState((previousNotifications) =>
                           previousNotifications.filter(
                              (previousNotification) =>
                                 previousNotification.id !== notification.id
                           )
                        )
                     }
                  />
               )}
            </For>
         </box>
      </window>
   );
}
