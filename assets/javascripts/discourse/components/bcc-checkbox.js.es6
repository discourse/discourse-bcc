import Component from "@ember/component";
import { computed } from "@ember/object";

export default Component.extend({
  tagName: "",

  bccAvailable: computed(
    "model.creatingPrivateMessage",
    "model.targetUsernames",
    function() {
      return (
        this.model.creatingPrivateMessage &&
        (this.model.targetUsernames || "").split(",").length > 1
      );
    }
  )
});
