import options from "../../../../options";
import { Accessor, createBinding, createComputed } from "ags";
import AstalNiri from "gi://AstalNiri";

const niri = AstalNiri.get_default();

function WorkspaceLabel({ workspaceName }: { workspaceName: string }) {
   const workspace = niri
      .get_workspaces()
      .find((workspace) => workspace.name === workspaceName);

   if (workspace === undefined)
      return <label cssClasses={["workspace-label"]} label={workspaceName} />;

   const isWorkspaceFocusedBinding = createBinding(workspace, "isFocused");
   const isWorkspaceUrgentBinding = createBinding(workspace, "isUrgent");
   const workspaceWindows = createBinding(workspace, "windows");

   const computedCssClasses = createComputed(
      [isWorkspaceFocusedBinding, isWorkspaceUrgentBinding, workspaceWindows],
      (isWorkspaceFocused, isWorkspaceUrgent, workspaceWindows) => {
         const cssClasses = ["workspace-label"];

         if (workspaceWindows.length > 0) {
            cssClasses.push("occupied");
         }

         if (isWorkspaceUrgent) {
            cssClasses.push("urgent");
         }

         if (isWorkspaceFocused) {
            cssClasses.push("focused");
         }

         return cssClasses;
      }
   );

   return <label cssClasses={computedCssClasses} label={`${workspaceName}`} />;
}

export default function () {
   return (
      <button cssClasses={["workspaces-button"]}>
         <box>
            {options.bar.niriWorkspaces.names.map((workspaceName) => (
               <WorkspaceLabel workspaceName={workspaceName} />
            ))}
         </box>
      </button>
   );
}
