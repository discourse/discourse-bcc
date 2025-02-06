import Component from "@ember/component";
import { tagName } from "@ember-decorators/component";
import computed from "discourse/lib/decorators";

@tagName("")
export default class BccCheckbox extends Component {
  @computed("creatingPrivateMessage", "targetRecipients", "targetGroups")
  bccAvailable() {
    return (
      this.currentUser.staff &&
      this.creatingPrivateMessage &&
      ((this.targetRecipients || "").split(",").filter(Boolean).length > 1 ||
        this.targetGroups)
    );
  }
}
