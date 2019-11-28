import Component from "@ember/component";
import { computed } from "@ember/object";

export default Component.extend({
  tagName: "",

  bccAvailable: computed(
    "creatingPrivateMessage",
    "targetUsernames",
    function() {
      return (
        this.currentUser.staff &&
        this.creatingPrivateMessage &&
        (this.targetUsernames || "").split(",").length > 1
      );
    }
  )
});
