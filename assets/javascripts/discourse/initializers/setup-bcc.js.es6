import { ajax } from "discourse/lib/ajax";
import { Result } from "discourse/adapters/rest";

export default {
  name: "setup-bcc",
  after: "inject-objects",

  initialize(container) {
    let composer = container.factoryFor("model:composer");
    if (composer) {
      composer.class.serializeOnCreate("use_bcc");
    }

    let adapter = container.lookup("adapter:post");
    adapter.reopen({
      createRecord(store, type, args) {
        if (type === "post" && args.use_bcc) {
          return ajax("/posts/bcc", {
            method: "POST",
            data: args
          }).then(json => {
            return new Result(json.post, json);
          });
        } else {
          delete args.use_bcc;
          return this._super(store, type, args);
        }
      }
    });
  }
};
