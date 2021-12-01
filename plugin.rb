# frozen_string_literal: true

# name: discourse-bcc
# about: Adds the ability to send separate PMs simultaneously
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-bcc

enabled_site_setting :bcc_enabled

after_initialize do
  require_relative "app/jobs/bcc_post"

  module ::DiscourseBCC
    BATCH_SIZE = 20
  end

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
    group_names = Set.new((@manager_params[:target_group_names] || '').split(','))

    Group.where('lower(name) in (?)', group_names).includes(group_users: :user).each do |g|
      g.group_users.each do |gu|
        usernames << gu.user.username unless gu.user_id == current_user.id
      end
    end

    emails = Set.new((@manager_params[:target_emails] || '').split(','))

    if (usernames.size + emails.size) < 2
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.too_few_users")) }
    end

    validator = PostValidator.new
    post = Post.new(raw: @manager_params[:raw], user: current_user)
    validator.validate(post)

    if post.errors[:raw].present?
      return render_bcc(status: false) { |result| result.add_error(post.errors[:raw]) }
    end

    # Queue up jobs in batches so that when sending hundreds or thousands of emails we
    # can take advantage of multiple workers
    batch_start = 0
    batch_end = DiscourseBCC::BATCH_SIZE - 1
    @manager_params.except(:target_users, :target_group_names, :target_emails)
    usernames = usernames.to_a
    emails = emails.to_a
    while batch_start <= usernames.size && usernames.size > 0
      Jobs.enqueue(
        :bcc_post,
        user_id: current_user.id,
        create_params: @manager_params,
        targets_key: 'target_usernames',
        targets: usernames[batch_start..batch_end]
      )
      batch_start += DiscourseBCC::BATCH_SIZE
      batch_end += DiscourseBCC::BATCH_SIZE
    end

    batch_start = 0
    batch_end = DiscourseBCC::BATCH_SIZE - 1
    while batch_start <= emails.size && emails.size > 0
      Jobs.enqueue(
        :bcc_post,
        user_id: current_user.id,
        create_params: @manager_params,
        targets_key: 'target_emails',
        targets: emails[batch_start..batch_end]
      )
      batch_start += DiscourseBCC::BATCH_SIZE
      batch_end += DiscourseBCC::BATCH_SIZE
    end

    return render_bcc(status: true) do |result|
      result.route_to = "/u/#{current_user.username_lower}/messages/sent"
      result.message = I18n.t("bcc.messages_queued")
    end
  end
end
