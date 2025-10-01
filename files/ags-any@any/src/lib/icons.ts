export default {
   fallback: {
      executable: "application-x-executable",
      notification: "dialog-information",
      video: "video-x-generic",
      audio: "audio-x-generic",
   },

   ui: {
      close: "window-close",
      colorpicker: "color-select",
      info: "help-info",
      link: "external-link",
      lock: "system-lock-screen",
      menu: "open-menu",
      refresh: "view-refresh",
      search: "system-search",
      settings: "emblem-system",
      themes: "preferences-desktop-theme",
      tick: "object-select",
      time: "hourglass",
      toolbars: "toolbars",
      warning: "dialog-warning",
      avatar: "avatar-default",

      arrow: {
         right: "pan-end",
         left: "pan-start",
         down: "pan-down",
         up: "pan-up",
      },
   },

   notification: {
      normal: "notifications",
      noisy: "notification-active",
   },

   audio: {
      mic: {
         muted: "microphone-disabled",
         low: "microphone-sensitivy-low",
         medium: "microphone-sensitivy-medium",
         high: "microphone-sensitivity-high",
      },

      volume: {
         muted: "audio-volume-muted",
         low: "audio-volume-low",
         medium: "audio-volume-medium",
         high: "audio-volume-high",
         overamplified: "audio-volume-overamplified",
      },
   },

   powerprofile: {
      balanced: "power-profile-balanced",
      powerSaver: "power-profile-power-saver",
      performance: "power-profile-performance",
   },

   recorder: {
      recording: "media-record",
      screencast: "media-record",
   },
};

export const substitutes = {};
