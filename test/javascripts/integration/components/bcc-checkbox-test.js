import { click } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import componentTest, {
  setupRenderingTest,
} from "discourse/tests/helpers/component-test";
import {
  count,
  discourseModule,
  exists,
} from "discourse/tests/helpers/qunit-helpers";

discourseModule("Integration | Component | bcc-checkbox", function (hooks) {
  setupRenderingTest(hooks);

  componentTest("it doesn't show up by default", {
    template: hbs`{{bcc-checkbox}}`,

    beforeEach() {
      this.currentUser.set("moderator", true);
    },

    test(assert) {
      assert.ok(!exists(".bcc-checkbox"));
    },
  });

  componentTest("doesn't show up for non-staff", {
    template: hbs`{{bcc-checkbox creatingPrivateMessage=true targetRecipients="evil,trout"}}`,

    async test(assert) {
      assert.ok(!exists(".bcc-checkbox"));
    },
  });

  componentTest("it shows up if a private message with at least 1 username", {
    template: hbs`{{bcc-checkbox checked=changeMe creatingPrivateMessage=true targetRecipients="evil,trout"}}`,

    beforeEach() {
      this.set("changeMe", false);
      this.currentUser.set("moderator", true);
    },

    async test(assert) {
      assert.strictEqual(this.changeMe, false);
      assert.strictEqual(count(".bcc-checkbox"), 1);
      assert.strictEqual(count(".bcc-checkbox input[type=checkbox]"), 1);
      await click(".bcc-checkbox input[type=checkbox]");
      assert.strictEqual(this.changeMe, true);
    },
  });
});
