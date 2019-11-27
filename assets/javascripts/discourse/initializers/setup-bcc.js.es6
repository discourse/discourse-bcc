export default {
  name: "setup-bcc",
  after: "inject-objects",

  initialize(container) {
    let composer = container.factoryFor("model:composer");
    if (composer) {
      composer.class.serializeOnCreate("use_bcc");
    }
  }
};
