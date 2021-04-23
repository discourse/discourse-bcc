import Component from "@ember/component";
import computed from "discourse-common/utils/decorators";

export default Component.extend({
  tagName: "",

  @computed("creatingPrivateMessage", "targetRecipients", "targetGroups")
  bccAvailable() {
    return (
      this.currentUser.staff &&
      this.creatingPrivateMessage &&
      ((this.targetRecipients || "").split(",").filter(Boolean).length > 1 ||
        this.targetGroups)
    );
  },
});
