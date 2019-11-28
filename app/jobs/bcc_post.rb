# frozen_string_literal: true

class ::Jobs::BccPost < ::Jobs::Base
  def execute(args)
    return unless SiteSetting.bcc_enabled?

    sender = User.find_by(id: args[:user_id])
    return unless sender.present?

    create_params = args[:create_params]
    create_params[:skip_validations] = true
    split_usernames = create_params.delete(:target_usernames).split(',')

    split_usernames.each do |username|
      creator = PostCreator.new(sender, create_params.merge(target_usernames: username))
      creator.create
    end
  end
end
