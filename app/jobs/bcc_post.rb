# frozen_string_literal: true

class ::Jobs::BccPost < ::Jobs::Base
  sidekiq_options queue: "low"

  def execute(args)
    return unless SiteSetting.bcc_enabled?

    sender = User.find_by(id: args[:user_id])
    return unless sender.present?

    targets = args[:targets]
    targets_key = args[:targets_key]
    create_params = args[:create_params]
    create_params[:skip_validations] = true

    send_to(targets, targets_key, create_params, sender)
  end

  private

  def send_to(targets, targets_key, params, sender)
    targets.each do |target|
      raw = params["raw"].gsub(/%{username}/i, target)
      raw.gsub!(/%{@username}/i, "@" + target)

      user = User.find_by_username_or_email(target)

      raw.gsub!(/%{name}/i, user.name) if user&.name

      creator = PostCreator.new(sender, params.merge(Hash[targets_key, target], raw: raw))
      creator.create
    end
  end
end
