import componentTest from "helpers/component-test";

moduleForComponent("bcc-checkbox", { integration: true });

componentTest("it doesn't show up by default", {
  template: "{{bcc-checkbox}}",
  beforeEach() {
    this.currentUser.set("moderator", true);
  },
  test(assert) {
    assert.ok(find(".bcc-checkbox").length === 0);
  }
});

componentTest("it doesn't show up with one username", {
  template: `{{bcc-checkbox creatingPrivateMessage=true targetUsernames="evil"}}`,

  beforeEach() {
    this.currentUser.set("moderator", true);
  },

  test(assert) {
    assert.ok(find(".bcc-checkbox").length === 0);
  }
});

componentTest("doesn't show up for non-staff", {
  template: `{{bcc-checkbox creatingPrivateMessage=true targetUsernames="evil,trout"}}`,

  async test(assert) {
    assert.ok(find(".bcc-checkbox").length === 0);
  }
});

componentTest(
  "it shows up if a private message with at least 2 target usernames",
  {
    beforeEach() {
      this.set("changeMe", false);
      this.currentUser.set("moderator", true);
    },

    template: `{{bcc-checkbox checked=changeMe creatingPrivateMessage=true targetUsernames="evil,trout"}}`,

    async test(assert) {
      assert.ok(!this.get("changeMe"));
      assert.ok(find(".bcc-checkbox").length === 1);
      assert.ok(find(".bcc-checkbox input[type=checkbox]").length === 1);
      await click(".bcc-checkbox input[type=checkbox]");
      assert.ok(this.get("changeMe"));
    }
  }
);
