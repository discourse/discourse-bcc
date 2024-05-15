# frozen_string_literal: true

# name: discourse-bcc
# about: Allows staff users to send individual personal messages to several users at once.
# meta_topic_id: 134721
# version: 0.1
# authors: Robin Ward
# url: https://github.com/discourse/discourse-bcc

enabled_site_setting :bcc_enabled

after_initialize do
  require_relative "app/jobs/bcc_post"
  require_relative "lib/posts_controller_extension"

  module ::DiscourseBCC
    BATCH_SIZE = 20
  end

  Discourse::Application.routes.append do
    post "/posts/bcc" => "posts#bcc", :constraints => StaffConstraint.new
  end

  # add_to_class doesn't support blocks
  reloadable_patch { ::PostsController.prepend(DiscourseBCC::PostsControllerExtension) }

  add_to_class(::PostsController, :bcc) do
    @manager_params = create_params

    if @manager_params[:archetype] != Archetype.private_message
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.pm_required")) }
    end

    usernames = Set.new((@manager_params[:target_usernames] || "").split(","))

    # Expand any groups
    group_names = Set.new((@manager_params[:target_group_names] || "").split(","))

    Group
      .where("lower(name) in (?)", group_names)
      .includes(group_users: :user)
      .each do |g|
        g.group_users.each do |gu|
          usernames << gu.user.username unless gu.user_id == current_user.id
        end
      end

    emails = Set.new((@manager_params[:target_emails] || "").split(","))

    if (usernames.size + emails.size) < 2
      return render_bcc(status: false) { |result| result.add_error(I18n.t("bcc.too_few_users")) }
    end

    validator = PostValidator.new
    post = Post.new(raw: @manager_params[:raw], user: current_user)
    validator.validate(post)

    if post.errors[:raw].present?
      return render_bcc(status: false) { |result| result.add_error(post.errors[:raw]) }
    end

    @manager_params.except!(:target_users, :target_group_names, :target_emails)

    # Queue up jobs in batches so that when sending hundreds or thousands of emails we
    # can take advantage of multiple workers
    batch_targets(usernames, "target_usernames")
    batch_targets(emails, "target_emails")

    return(
      render_bcc(status: true) do |result|
        result.route_to = "/u/#{current_user.username_lower}/messages/sent"
        result.message = I18n.t("bcc.messages_queued")
      end
    )
  end
end
