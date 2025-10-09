import { Accessor, createComputed, createState, For, onCleanup } from "ags";
import { Astal, Gdk, Gtk } from "ags/gtk4";
import app from "ags/gtk4/app";
import { timeout } from "ags/time";
import AstalNotifd from "gi://AstalNotifd";
import options from "../../../options";
import { NotificationBox } from "../../composables/NotificationsBox";

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
         cssClasses={["notifications-window"]}
         gdkmonitor={gdkmonitor}
         name={options.notificationToasts.name}
         namespace={options.notificationToasts.name}
         layer={Astal.Layer.OVERLAY}
         anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
         exclusivity={Astal.Exclusivity.NORMAL}
         keymode={Astal.Keymode.NONE}
         application={app}
         visible={visible}
      >
         <box
            cssClasses={["notifications-box"]}
            orientation={Gtk.Orientation.VERTICAL}
         >
            <For each={notificationsState}>
               {(notification) => (
                  <NotificationBox
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
