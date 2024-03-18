# frozen_string_literal: true

class ::Jobs::BccPost < ::Jobs::Base
  sidekiq_options queue: "low"

  def execute(args)
    return unless SiteSetting.bcc_enabled?
    return unless sender = User.find_by(id: args[:user_id])

    targets = args[:targets]
    targets_key = args[:targets_key]
    create_params = args[:create_params]
    create_params[:skip_validations] = true

    send_to(targets, targets_key, create_params, sender)
  end

  private

  def send_to(targets, targets_key, params, sender)
    targets.each do |target|
      name = User.find_by_username_or_email(target)&.name

      raw = params["raw"].dup
      raw.gsub!(/%{username}/i, target)
      raw.gsub!(/%{@username}/i, "@" + target)
      raw.gsub!(/%{name}/i, name) if name.present?

      PostCreator.new(sender, params.merge(Hash[targets_key, target], raw: raw)).create
    end
  end
end
