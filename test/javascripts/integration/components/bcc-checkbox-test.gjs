import { tracked } from "@glimmer/tracking";
import { click, render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import BccCheckbox from "discourse/plugins/discourse-bcc/discourse/components/bcc-checkbox";

module("Integration | Component | bcc-checkbox", function (hooks) {
  setupRenderingTest(hooks);

  test("doesn't show up by default", async function (assert) {
    this.currentUser.set("moderator", true);

    await render(<template><BccCheckbox /></template>);

    assert.dom(".bcc-checkbox").doesNotExist();
  });

  test("doesn't show up for non-staff", async function (assert) {
    await render(<template>
      <BccCheckbox
        @creatingPrivateMessage={{true}}
        @targetRecipients="evil,trout"
      />
    </template>);

    assert.dom(".bcc-checkbox").doesNotExist();
  });

  test("shows up if a private message with at least 1 username", async function (assert) {
    class State {
      @tracked changeMe = false;
    }

    const testState = new State();

    this.currentUser.set("moderator", true);

    await render(<template>
      <BccCheckbox
        @checked={{testState.changeMe}}
        @creatingPrivateMessage={{true}}
        @targetRecipients="evil,trout"
      />
    </template>);

    assert.false(this.changeMe);
    assert.dom(".bcc-checkbox").exists();
    assert.dom(".bcc-checkbox input[type=checkbox]").exists();

    await click(".bcc-checkbox input[type=checkbox]");
    assert.true(this.changeMe);
  });
});
