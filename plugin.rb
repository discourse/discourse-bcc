# frozen_string_literal: true

# name: discourse-bcc
# about: Adds the ability to send separate PMs simultaneously
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-bcc

enabled_site_setting :bcc_enabled

after_initialize do
  require_relative "app/jobs/bcc_post"

  Discourse::Application.routes.append do
    post '/posts/bcc' => 'posts#bcc', constraints: StaffConstraint.new
  end

  # add_to_class doesn't support blocks
  reloadable_patch do
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
  end

  add_to_class(::PostsController, :bcc) do
    @manager_params = create_params

    if @manager_params[:archetype] != Archetype.private_message
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.pm_required")) }
    end

    usernames = Set.new((@manager_params[:target_usernames] || '').split(','))

    # Expand any groups
    group_names = (@manager_params.delete(:target_group_names) || '').split(',')
    Group.where(name: group_names).includes(group_users: :user).each do |g|
      g.group_users.each { |gu| usernames << gu.user.username }
    end

    if usernames.size < 2
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.too_few_users")) }
    end

    @manager_params[:target_usernames] = usernames.to_a.join(',')

    validator = PostValidator.new
    post = Post.new(raw: @manager_params[:raw], user: current_user)
    validator.validate(post)

    if post.errors[:raw].present?
      return render_bcc(status: false) { |result| result.add_error(post.errors[:raw]) }
    end

    Jobs.enqueue(:bcc_post, user_id: current_user.id, create_params: @manager_params)

    return render_bcc(status: true) do |result|
      result.route_to = "/u/#{current_user.username_lower}/messages"
      result.message = I18n.t("bcc.messages_queued")
    end
  end
end
