import { Result } from "discourse/adapters/rest";
import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "setup-bcc",
  after: "inject-objects",

  initialize(container) {
    let composer = container.factoryFor("model:composer");
    if (composer) {
      composer.class.serializeOnCreate("use_bcc");
      composer.class.serializeToDraft("use_bcc");
    }

    withPluginApi("0.8.10", (api) => {
      api.modifyClass("adapter:post", {
        pluginId: "discourse-bcc",

        createRecord(store, type, args) {
          if (type === "post" && args.use_bcc) {
            return ajax("/posts/bcc", {
              method: "POST",
              data: args,
            }).then((json) => {
              return new Result(json.post, json);
            });
          } else {
            delete args.use_bcc;
            return this._super(store, type, args);
          }
        },
      });
    });
  },
};
