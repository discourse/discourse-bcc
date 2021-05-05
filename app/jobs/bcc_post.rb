# frozen_string_literal: true

class ::Jobs::BccPost < ::Jobs::Base
  def execute(args)
    return unless SiteSetting.bcc_enabled?

    sender = User.find_by(id: args[:user_id])
    return unless sender.present?

    create_params = args[:create_params]
    create_params[:skip_validations] = true

    split_usernames = (create_params.delete(:target_usernames) || '').split(',')
    split_emails = (create_params.delete(:target_emails) || '').split(',')

    send_to(split_usernames, :target_usernames, create_params, sender)
    send_to(split_emails, :target_emails, create_params, sender)
  end

  private

  def send_to(targets, targets_key, params, sender)
    targets.each do |target|
      temp_params = params.clone
      temp_params["raw"] = temp_params["raw"].gsub(/%{username}/i, target)
      temp_params["raw"] = temp_params["raw"].gsub(/%{@username}/i, "@" + target)
      user = User.find_by_username_or_email(target)
      if !user.nil? then
        temp_params["raw"] = temp_params["raw"].gsub(/%{name}/i, user.name)
      end
      creator = PostCreator.new(sender, temp_params.merge(Hash[targets_key, target]))
      creator.create
    end
  end
end
