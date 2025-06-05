import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import BccCheckbox0 from "../../components/bcc-checkbox";

@tagName("div")
@classNames("composer-fields-outlet", "bcc-checkbox")
export default class BccCheckbox extends Component {
  <template>
    <BccCheckbox0
      @creatingPrivateMessage={{this.model.creatingPrivateMessage}}
      @targetRecipients={{this.model.targetRecipients}}
      @checked={{this.model.use_bcc}}
      @targetGroups={{this.model.hasTargetGroups}}
    />
  </template>
}
