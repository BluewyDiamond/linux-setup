import {
   Accessor,
   createBinding,
   createComputed,
   createExternal,
   With,
} from "ags";
import AstalPowerProfiles from "gi://AstalPowerProfiles";
import AstalWp from "gi://AstalWp";
import options from "../../../../options";
import AstalNotifd from "gi://AstalNotifd";
import Adw from "gi://Adw";
import app from "ags/gtk4/app";

const powerprofiles = AstalPowerProfiles.get_default();
const wp = AstalWp.get_default();
const audio = wp.get_audio();
const video = wp.get_video();
const notifd = AstalNotifd.get_default();

export default function () {
   const defaultMicrophoneExternal = createExternal<null | AstalWp.Endpoint>(
      null,
      (set) => {
         const onMicrophonesChanged = () => {
            const microphones = audio.get_microphones();
            if (microphones === null) return;

            const foundMicrophone = microphones.find(
               (microphone) => microphone.isDefault
            );

            if (foundMicrophone === undefined) {
               return;
            }

            set(foundMicrophone);
         };

         const microphonesConnectionId = audio.connect(
            "notify::microphones",
            (_) => {
               onMicrophonesChanged();
            }
         );

         onMicrophonesChanged();

         return () => audio.disconnect(microphonesConnectionId);
      }
   );

   const defaultSpeakerExternal = createExternal<null | AstalWp.Endpoint>(
      null,
      (set) => {
         const onMicrophonesChanged = () => {
            const speakers = audio.get_speakers();
            if (speakers === null) return;

            const foundDefaultSpeaker = speakers.find(
               (speaker) => speaker.isDefault
            );

            if (foundDefaultSpeaker === undefined) {
               return;
            }

            set(foundDefaultSpeaker);
         };

         const speakersConnectionId = audio.connect("notify::speakers", (_) => {
            onMicrophonesChanged();
         });

         onMicrophonesChanged();

         return () => audio.disconnect(speakersConnectionId);
      }
   );

   const isControlCenterVisibleExternal = createExternal<boolean>(
      false,

      (set) => {
         const onWindowToggled = () => {
            const foundControlCenterWindow = app
               .get_windows()
               .find((window) => window.name === options.controlCenter.name);

            if (foundControlCenterWindow === undefined) return;

            if (foundControlCenterWindow.visible) {
               set(true);
            } else {
               set(false);
            }
         };

         const toggledWindowConnectionId = app.connect(
            "window-toggled",
            (_broken_value) => {
               onWindowToggled();
            }
         );

         onWindowToggled();

         return () => app.disconnect(toggledWindowConnectionId);
      }
   );

   // // // // // // // // // // // // // // // // // // // // // // // // //

   const forNotificationsIndicatorComputed: Accessor<[boolean, string | null]> =
      createComputed(
         [createBinding(notifd, "notifications")],

         (notifications) => {
            if (notifications.length <= 0) {
               return [false, null];
            }

            return [
               true,
               options.bar.indicators.notifications.icons.notificationNoisy,
            ];
         }
      );

   const forPowerProfileIndicatorComputed: Accessor<[boolean, string | null]> =
      createComputed(
         [createBinding(powerprofiles, "activeProfile")],
         (activePowerProfile) => {
            if (activePowerProfile === "performance") {
               return [
                  true,
                  options.bar.indicators.powerprofile.icons.performance,
               ];
            } else if (activePowerProfile === "balanced") {
               return [
                  false,
                  options.bar.indicators.powerprofile.icons.performance,
               ];
            } else if (activePowerProfile === "powersaving") {
               return [
                  true,
                  options.bar.indicators.powerprofile.icons.powerSaver,
               ];
            } else {
               return [false, null];
            }
         }
      );

   const forVideoRecordersIndicatorComputed: Accessor<
      [boolean, string | null]
   > = createComputed([createBinding(video, "recorders")], (videoRecorders) => {
      if (videoRecorders.length <= 0) {
         return [false, null];
      }

      return [true, options.bar.indicators.icons.screenshare];
   });

   const forMicrophoneRecordersIndicatorComputed: Accessor<
      [boolean, (() => Accessor<string>) | null]
   > = createComputed(
      [createBinding(audio, "recorders"), defaultMicrophoneExternal],

      (microphoneRecorders, defaultMicrophone) => {
         if (microphoneRecorders.length <= 0) {
            return [false, null];
         }

         if (defaultMicrophone === null) {
            return [true, null];
         }

         const getDefaultMicrophoneVolumeIconComputed = () => {
            return createComputed(
               [createBinding(defaultMicrophone, "volume")],
               (defaultMicrophoneVolume) => {
                  if (defaultMicrophoneVolume > 0.67) {
                     return options.bar.indicators.microphoneRecorders.icons
                        .microphoneHigh;
                  } else if (defaultMicrophoneVolume > 0.34) {
                     return options.bar.indicators.microphoneRecorders.icons
                        .microphoneMedium;
                  } else if (defaultMicrophoneVolume > 0.1) {
                     return options.bar.indicators.microphoneRecorders.icons
                        .microphoneLow;
                  } else {
                     return options.bar.indicators.microphoneRecorders.icons
                        .microphoneMuted;
                  }
               }
            );
         };

         return [true, getDefaultMicrophoneVolumeIconComputed];
      }
   );

   // TODO: the recorders part lol (the name will be misleading for now)
   // also forget about default since apps can connect to non default
   // we have to check for any connections to any speaker
   // something akin to microphone speaker but for speaker
   // tldr: missing speakerRecorders parameter
   const forSpeakerRecordersIndicatorComputed: Accessor<
      [boolean, (() => Accessor<string>) | null]
   > = createComputed([defaultSpeakerExternal], (defaultSpeaker) => {
      if (defaultSpeaker === null) {
         return [true, null];
      }

      const getDefaultVolumeIconComputed = () => {
         return createComputed(
            [createBinding(defaultSpeaker, "volume")],

            (defaultSpeakerVolume) => {
               if (defaultSpeakerVolume <= 0) {
                  return options.bar.indicators.speaker.icons.speakerMuted;
               } else if (defaultSpeakerVolume <= 0.34) {
                  return options.bar.indicators.speaker.icons.speakerLow;
               } else if (defaultSpeakerVolume <= 0.67) {
                  return options.bar.indicators.speaker.icons.speakerMedium;
               } else if (defaultSpeakerVolume <= 1) {
                  return options.bar.indicators.speaker.icons.speakerHigh;
               } else {
                  return options.bar.indicators.speaker.icons
                     .speakerOveramplified;
               }
            }
         );
      };

      return [true, getDefaultVolumeIconComputed];
   });

   const forControlCenterIndicatorComputed: Accessor<[boolean, boolean]> =
      createComputed(
         [
            forNotificationsIndicatorComputed,
            forPowerProfileIndicatorComputed,
            forVideoRecordersIndicatorComputed,
            forMicrophoneRecordersIndicatorComputed,
            forSpeakerRecordersIndicatorComputed,
            isControlCenterVisibleExternal,
         ],
         (a, b, c, d, e, f) => {
            const arr = [a, b, c, d, e];
            const visible = !(arr.some((item) => item[0] === true) ?? false);

            return [visible, f];
         }
      );

   return (
      <button
         cssClasses={createComputed(
            [isControlCenterVisibleExternal],

            (isControlCenterVisible) => {
               const cssClasses = ["indicators-button"];
               if (!isControlCenterVisible) {
                  return cssClasses;
               }

               cssClasses.push("active");
               return cssClasses;
            }
         )}
         onClicked={() => app.toggle_window(options.controlCenter.name)}
      >
         <box cssClasses={["indicators-box"]}>
            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forNotificationsIndicatorComputed],
                  (forNotificationsIndicator) => forNotificationsIndicator[0]
               )}
            >
               <With value={forNotificationsIndicatorComputed}>
                  {(forNotificationsIndicator) => {
                     const [visible, iconName] = forNotificationsIndicator;

                     if (!visible) {
                        return;
                     }

                     if (iconName === null) {
                        return;
                     }

                     return <image iconName={iconName} />;
                  }}
               </With>
            </Adw.Bin>

            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forPowerProfileIndicatorComputed],
                  (forPowerProfileIndicator) => forPowerProfileIndicator[0]
               )}
            >
               <With value={forPowerProfileIndicatorComputed}>
                  {(forPowerProfileIndicator) => {
                     const [visible, iconName] = forPowerProfileIndicator;

                     if (!visible) {
                        return;
                     }

                     if (iconName === null) {
                        return;
                     }

                     return <image iconName={iconName} />;
                  }}
               </With>
            </Adw.Bin>

            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forVideoRecordersIndicatorComputed],
                  (forVideoRecordersIndicator) => forVideoRecordersIndicator[0]
               )}
            >
               <With value={forVideoRecordersIndicatorComputed}>
                  {(forVideoRecordersIndicator) => {
                     const [visible, iconName] = forVideoRecordersIndicator;

                     if (!visible) {
                        return;
                     }

                     if (iconName === null) {
                        return;
                     }

                     return <image iconName={iconName} />;
                  }}
               </With>
            </Adw.Bin>

            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forMicrophoneRecordersIndicatorComputed],

                  (forMicrophoneRecordersIndicator) =>
                     forMicrophoneRecordersIndicator[0]
               )}
            >
               <With value={forMicrophoneRecordersIndicatorComputed}>
                  {(forMicrophoneRecordersIndicator) => {
                     const [visible, getDefaultMicrophoneVolumeComputed] =
                        forMicrophoneRecordersIndicator;

                     if (!visible) {
                        return;
                     }

                     if (getDefaultMicrophoneVolumeComputed === null) {
                        return <label label="no default mic :3" />;
                     }

                     return (
                        <image
                           iconName={getDefaultMicrophoneVolumeComputed()}
                        />
                     );
                  }}
               </With>
            </Adw.Bin>

            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forSpeakerRecordersIndicatorComputed],
                  (forSpeakerRecordersIndicator) =>
                     forSpeakerRecordersIndicator[0]
               )}
            >
               <With value={forSpeakerRecordersIndicatorComputed}>
                  {(forSpeakerRecordersIndicator) => {
                     const [visible, getDefaultSpeakerVolumeIconComputed] =
                        forSpeakerRecordersIndicator;

                     if (!visible) {
                        return;
                     }

                     if (getDefaultSpeakerVolumeIconComputed === null) {
                        return <label label="no default speaker :3" />;
                     }

                     return (
                        <image
                           iconName={getDefaultSpeakerVolumeIconComputed()}
                        />
                     );
                  }}
               </With>
            </Adw.Bin>

            <Adw.Bin
               cssClasses={["indicator-widget"]}
               visible={createComputed(
                  [forControlCenterIndicatorComputed],
                  (forControlCenterIndicator) => forControlCenterIndicator[0]
               )}
            >
               <With value={forControlCenterIndicatorComputed}>
                  {(forControlCenterIndicator) => {
                     const [_, visible] = forControlCenterIndicator;

                     if (!visible) {
                        return (
                           <image
                              iconName={
                                 options.bar.indicators.controlCenter.icons
                                    .arrowDown
                              }
                           />
                        );
                     }

                     return (
                        <image
                           iconName={
                              options.bar.indicators.controlCenter.icons.arrowUp
                           }
                        />
                     );
                  }}
               </With>
            </Adw.Bin>
         </box>
      </button>
   );
}
