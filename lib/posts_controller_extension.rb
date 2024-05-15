# frozen_string_literal: true

module DiscourseBCC
  module PostsControllerExtension
    extend ActiveSupport::Concern

    def render_bcc(status:)
      result = NewPostResult.new(:bcc, status)
      yield result if block_given?
      render(
        json: serialize_data(result, NewPostResultSerializer, root: false),
        status: result.success? ? 200 : 422,
      )
    end

    def batch_targets(targets, targets_key)
      targets.each_slice(DiscourseBCC::BATCH_SIZE) do |t|
        Jobs.enqueue(
          :bcc_post,
          user_id: current_user.id,
          create_params: @manager_params,
          targets_key: targets_key,
          targets: t,
        )
      end
    end
  end
end
