# frozen_string_literal: true

# name: discourse-bcc
# about: Adds the ability to send separate PMs simultaneously
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-bcc

enabled_site_setting :bcc_enabled

after_initialize do
  Discourse::Application.routes.append do
    post '/posts/bcc' => 'posts#bcc'
  end

  add_to_class(::PostsController, :bcc) do
    raise "bcc it!"
  end
end
