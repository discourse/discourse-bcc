# frozen_string_literal: true

# name: discourse-bcc
# about: Adds the ability to send separate PMs simultaneously
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-bcc

enabled_site_setting :bcc_enabled

after_initialize do
  require_dependency 'posts_controller'

  Discourse::Application.routes.append do
    post '/posts/bcc' => 'posts#bcc', constraints: StaffConstraint.new
  end

  # add_to_class doesn't support blocks
  class ::PostsController < ApplicationController
    protected
    def render_bcc(status:)
      result = NewPostResult.new(:bcc, status)
      yield result if block_given?
      render(
        json: serialize_data(result, NewPostResultSerializer, root: false),
        status: result.success? ? 200 : 422
      )
    end
  end

  add_to_class(::PostsController, :bcc) do
    @manager_params = create_params

    if @manager_params[:archetype] != Archetype.private_message
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.pm_required")) }
    end

    usernames = (@manager_params[:target_usernames] || '').split(',')
    if usernames.size < 2
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.too_few_users")) }
    end

    validator = PostValidator.new
    post = Post.new(raw: @manager_params[:raw], user: current_user)
    validator.validate(post)

    if post.errors[:raw].present?
      return render_bcc(status: false) { |result| result.add_error(post.errors[:raw]) }
    end

    return render_bcc(status: true)
  end
end
