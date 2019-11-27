import componentTest from "helpers/component-test";

moduleForComponent("bcc-checkbox", { integration: true });

componentTest("it doesn't show up by default", {
  template: "{{bcc-checkbox}}",

  test(assert) {
    assert.ok(find(".bcc-checkbox").length === 0);
  }
});

componentTest("it doesn't show up with one username", {
  template: `{{bcc-checkbox creatingPrivateMessage=true targetUsernames="evil"}}`,

  test(assert) {
    assert.ok(find(".bcc-checkbox").length === 0);
  }
});

componentTest(
  "it shows up if a private message with at least 2 target usernames",
  {
    beforeEach() {
      this.set("changeMe", false);
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
