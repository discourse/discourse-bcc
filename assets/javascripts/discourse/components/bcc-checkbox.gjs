import Component, { Input } from "@ember/component";
import { tagName } from "@ember-decorators/component";
import computed from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

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

  <template>
    {{#if this.bccAvailable}}
      <div class="bcc-checkbox">
        <label>
          <Input @type="checkbox" @checked={{this.checked}} />
          {{i18n "discourse_bcc.use_bcc"}}
        </label>
      </div>
    {{/if}}
  </template>
}
